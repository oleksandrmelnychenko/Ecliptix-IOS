//
//  EcliptixProtocolSystem.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 29.05.2025.
//

import Foundation
import SwiftProtobuf

public class EcliptixProtocolSystem {
    private var connectSession: ConnectSession?
    private let ecliptixSystemIdentityKeys: EcliptixSystemIdentityKeys

    init(ecliptixSystemIdentityKeys: EcliptixSystemIdentityKeys) {
        self.ecliptixSystemIdentityKeys = ecliptixSystemIdentityKeys
    }
    
    func beginDataCenterPubKeyExchange(
        connectId: UInt32,
        exchangeType: Ecliptix_Proto_PubKeyExchangeType
    ) throws -> Ecliptix_Proto_PubKeyExchange {
        debugPrint("[ShieldPro] Beginning exchange \(exchangeType), generated ConnectId: \(connectId)")
        debugPrint("[ShieldPro] Generating ephemeral key pair.")
        
        ecliptixSystemIdentityKeys.generateEphemeralKeyPair()
        
        let localBundleResult = ecliptixSystemIdentityKeys.createPublicBundle()
        guard localBundleResult.isOk else {
            throw ShieldChainStepError("Failed to create local public bundle: \(try localBundleResult.unwrapErr())")
        }
        let localBundle = try localBundleResult.unwrap()
        let protoBundle = localBundle.toProtobufExchange()
        
        let sessionResult = ConnectSession.create(connectId: connectId, localBundle: localBundle, isInitiator: true)
        guard sessionResult.isOk else {
            throw ShieldChainStepError("Failed to create session: \(try sessionResult.unwrapErr())")
        }
        connectSession = try sessionResult.unwrap()
        
        let dhPublicKeyResult = connectSession!.getCurrentSenderDhPublicKey()
        if dhPublicKeyResult.isErr {
            throw ShieldChainStepError("Sender DH key not initialized: \(try dhPublicKeyResult.unwrapErr())")
        }
        let dhPublicKey = try dhPublicKeyResult.unwrap()
        
        var pubKeyExchange = Ecliptix_Proto_PubKeyExchange()
        pubKeyExchange.state = .init_
        pubKeyExchange.ofType = exchangeType
        do {
            pubKeyExchange.payload = try protoBundle.serializedData()
        } catch {
            throw ShieldChainStepError("Failed to serialize protoBundle: \(error.localizedDescription)")
        }
        pubKeyExchange.initialDhPublicKey = Data(dhPublicKey!)

        
        return pubKeyExchange
    }

    
    func processAndRespondToPubKeyExchange(
        connectId: UInt32,
        peerInitialMessageProto: Ecliptix_Proto_PubKeyExchange
    ) throws -> Ecliptix_Proto_PubKeyExchange {

        guard peerInitialMessageProto.state == .init_ else {
            throw ShieldChainStepError("Expected peer message state to be Init.")
        }

        let exchangeType = peerInitialMessageProto.ofType
        debugPrint("[ShieldPro] Processing exchange request \(exchangeType), generated Session ID: \(connectId)")

        var rootKeyHandle: SodiumSecureMemoryHandle? = nil
        
        defer {
            rootKeyHandle?.dispose()
        }

        do {
            let peerBundleProto = try Helpers.parseFromBytes(Ecliptix_Proto_PublicKeyBundle.self, data: peerInitialMessageProto.payload)
            let peerBundleResult = LocalPublicKeyBundle.fromProtobufExchange(peerBundleProto)
            guard peerBundleResult.isOk else {
                throw ShieldChainStepError("Failed to convert peer bundle: \(try peerBundleResult.unwrapErr())")
            }
            let peerBundle = try peerBundleResult.unwrap()

            let spkValidResult = EcliptixSystemIdentityKeys.verifyRemoteSpkSignature(
                remoteIdentityEd25519: peerBundle.identityEd25519,
                remoteSpkPublic: peerBundle.signedPreKeyPublic,
                remoteSpkSignature: peerBundle.signedPreKeySignature
            )
            guard spkValidResult.isOk, try spkValidResult.unwrap() else {
                let errorMsg = spkValidResult.isOk
                    ? "Invalid signature"
                    : String(describing: try? spkValidResult.unwrapErr().description)

                throw ShieldChainStepError("SPK signature validation failed: \(errorMsg)")
            }

            debugPrint("[ShieldPro] Generating ephemeral key for response.")
            ecliptixSystemIdentityKeys.generateEphemeralKeyPair()

            let localBundleResult = ecliptixSystemIdentityKeys.createPublicBundle()
            guard localBundleResult.isOk else {
                throw ShieldChainStepError("Failed to create local public bundle: \(try localBundleResult.unwrapErr())")
            }
            let localBundle = try localBundleResult.unwrap()
            let protoBundle = localBundle.toProtobufExchange()

            let sessionResult = ConnectSession.create(connectId: connectId, localBundle: localBundle, isInitiator: false)
            guard sessionResult.isOk else {
                throw ShieldChainStepError("Failed to create session: \(try sessionResult.unwrapErr())")
            }
            connectSession = try sessionResult.unwrap()

            debugPrint("[ShieldPro] Deriving shared secret as recipient.")
            let firstPreKey: OneTimePreKeyRecord? = peerBundle.oneTimePreKeys.first

            // maybe error here
            let deriveResult: Result<SodiumSecureMemoryHandle, EcliptixProtocolFailure> = ecliptixSystemIdentityKeys.calculateSharedSecretAsRecipient(
                remoteIdentityPublicKeyX: peerBundle.identityX25519,
                remoteEphemeralPublicKeyX: peerBundle.ephemeralX25519!,
                usedLocalOpkId: firstPreKey?.preKeyId,
                info: Constants.x3dhInfo
            )
            
            guard deriveResult.isOk else {
                throw ShieldChainStepError("Shared secret derivation failed: \(try deriveResult.unwrapErr())")
            }
            rootKeyHandle = try deriveResult.unwrap()

            var rootKeyBytes = Data(count: Constants.x25519KeySize)
            let readResult = rootKeyBytes.withUnsafeMutableBytes { buffer in
                rootKeyHandle!.read(into: buffer)
            }
            guard readResult.isOk else {
                throw ShieldChainStepError("Failed to read root key: \(try readResult.unwrapErr())")
            }
            debugPrint("[ShieldPro] Root Key: \(rootKeyBytes.hexEncodedString())")

            try connectSession!.setPeerBundle(peerBundle)
            _ = connectSession!.setConnectionState(.pending)

            var peerDhKey = peerInitialMessageProto.initialDhPublicKey
            debugPrint("[ShieldPro] Peer Initial DH Public Key: \(peerDhKey.hexEncodedString())")

            let finalizeResult = connectSession!.finalizeChainAndDhKeys(initialRootKey: &rootKeyBytes, initialPeerDhPublicKey: &peerDhKey)
            guard finalizeResult.isOk else {
                throw ShieldChainStepError("Failed to finalize chain keys: \(try finalizeResult.unwrapErr())")
            }

            let stateResult = connectSession!.setConnectionState(.complete)
            guard stateResult.isOk else {
                throw ShieldChainStepError("Failed to set Complete state: \(try stateResult.unwrapErr())")
            }

            _ = SodiumInterop.secureWipe(&rootKeyBytes)

            let dhPublicKeyResult = connectSession!.getCurrentSenderDhPublicKey()
            guard dhPublicKeyResult.isOk else {
                throw ShieldChainStepError("Failed to get sender DH key: \(try dhPublicKeyResult.unwrapErr())")
            }
            let dhPublicKey = try dhPublicKeyResult.unwrap()

            var pubKeyExchange = Ecliptix_Proto_PubKeyExchange()
            pubKeyExchange.state = .pending
            pubKeyExchange.ofType = exchangeType
            pubKeyExchange.payload = try protoBundle.serializedData()
            pubKeyExchange.initialDhPublicKey = dhPublicKey!

            return pubKeyExchange

        } catch {
            debugPrint("[ShieldPro] Error in processAndRespondToPubKeyExchange for session \(connectId): \(error)")
            throw error
        }
    }

    
    func completeDataCenterPubKeyExchange(
        connectId: UInt32,
        exchangeType: Ecliptix_Proto_PubKeyExchangeType,
        peerMessage: Ecliptix_Proto_PubKeyExchange
    ) throws {
        debugPrint("[ShieldPro] Completing exchange for session \(connectId) (\(exchangeType)).")
        
        let peerBundleProto = try Helpers.parseFromBytes(Ecliptix_Proto_PublicKeyBundle.self, data: peerMessage.payload)
        
        let peerBundleResult = LocalPublicKeyBundle.fromProtobufExchange(peerBundleProto)
        guard peerBundleResult.isOk else {
            throw ShieldChainStepError("Failed to convert peer bundle: \(try peerBundleResult.unwrapErr())")
        }
        let peerBundle = try peerBundleResult.unwrap()
        
        debugPrint("[ShieldPro] Verifying remote SPK signature for completion.")
        let spkValidResult = EcliptixSystemIdentityKeys.verifyRemoteSpkSignature(
            remoteIdentityEd25519: peerBundle.identityEd25519,
            remoteSpkPublic: peerBundle.signedPreKeyPublic,
            remoteSpkSignature: peerBundle.signedPreKeySignature
        )
        if !spkValidResult.isOk || (try? spkValidResult.unwrap()) != true {
            throw ShieldChainStepError("SPK signature validation failed: \(spkValidResult.isOk ? "Invalid signature" : "\(try spkValidResult.unwrapErr())")")
        }
        
        debugPrint("[ShieldPro] Deriving X3DH shared secret.")
        let deriveResult = ecliptixSystemIdentityKeys.x3dhDeriveSharedSecret(remoteBundle: peerBundle, info: Constants.x3dhInfo)
        guard deriveResult.isOk else {
            throw ShieldChainStepError("Shared secret derivation failed: \(try deriveResult.unwrapErr())")
        }
        
        let rootKeyHandle = try deriveResult.unwrap()
        
        var rootKeyBytes = Data(count: Constants.x25519KeySize)
        let result = rootKeyBytes.withUnsafeMutableBytes { buffer in
            rootKeyHandle.read(into: buffer)
        }

        guard result.isOk else {
            throw ShieldChainStepError("Failed to read root key: \(try result.unwrapErr())")
        }
        
        debugPrint("[ShieldPro] Derived Root Key: \(rootKeyBytes.hexEncodedString())")
        
        var initialDhPublicKeyCopy = peerMessage.initialDhPublicKey
        let finalizeResult = connectSession!.finalizeChainAndDhKeys(initialRootKey: &rootKeyBytes, initialPeerDhPublicKey: &initialDhPublicKeyCopy)
        guard finalizeResult.isOk else {
            throw ShieldChainStepError("Failed to finalize chain keys: \(try finalizeResult.unwrapErr())")
        }
        
        try connectSession!.setPeerBundle(peerBundle)
        
        let stateResult = connectSession!.setConnectionState(.complete)
        guard stateResult.isOk else {
            throw ShieldChainStepError("Failed to set Complete state: \(try stateResult.unwrapErr())")
        }
        
        _ = SodiumInterop.secureWipe(&rootKeyBytes)
    }

    
    func produceOutboundMessage(connectId: UInt32, exchangeType: Ecliptix_Proto_PubKeyExchangeType, plainPayload: Data) throws -> Ecliptix_Proto_CipherPayload {
        debugPrint("[ShieldPro] Producing outbound message for session \(connectId) (\(exchangeType)).")
        
        var ciphertext: Data? = nil
        var tag: Data? = nil
        var messageKeyClone: ShieldMessageKey? = nil
        
        defer {
            messageKeyClone?.dispose()
            _ = SodiumInterop.secureWipe(&ciphertext)
            _ = SodiumInterop.secureWipe(&tag)
        }
        
        do {
            debugPrint("[ShieldPro] Preparing next send message.")
            let prepResult = connectSession!.prepareNextSendMessage()
            
            guard prepResult.isOk else {
                throw ShieldChainStepError("Failed to prepare outgoing message key: \(try prepResult.unwrapErr())")
            }
            
            let prepValues = try prepResult.unwrap()
            let messageKey = prepValues.messageKey
            let includeDhKey = prepValues.includeDhKey
            
            let nonceResult = connectSession!.generateNextNonce()
            guard nonceResult.isOk else {
                throw ShieldChainStepError("Failed to generate nonce: \(try nonceResult.unwrapErr())")
            }
            
            let nonce = try nonceResult.unwrap()
            
            debugPrint("[ShieldPro][Encrypt] Nonce: \(nonce.hexEncodedString())")
            debugPrint("[ShieldPro][Encrypt] Plaintext: \(plainPayload.hexEncodedString())")
            
            
            let newSenderDhPublicKey: Data? = includeDhKey ? try connectSession!.getCurrentSenderDhPublicKey()
                .Match(
                    onSuccess: { value in
                        return value
                    },
                    onFailure: { error in
                        throw ShieldChainStepError("Failed to get sender DH key: \(error.localizedDescription)")
                    }
                ) : nil
            
            if newSenderDhPublicKey != nil {
                debugPrint("[ShieldPro] Including new DH Public Key: \(newSenderDhPublicKey!.hexEncodedString())")
            }
            
            var messageKeyBytes = Data(repeating: 0, count: Constants.aesKeySize)
            _ = messageKey.readKeyMaterial(into: &messageKeyBytes)
            debugPrint("[ShieldPro][Encrypt] Message Key: \(messageKeyBytes.hexEncodedString())")
            
            let cloneResult = ShieldMessageKey.new(index: messageKey.index, keyMaterial: &messageKeyBytes)
            guard cloneResult.isOk else {
                throw ShieldChainStepError("Failed to clone message key: \(try cloneResult.unwrapErr())")
            }
            
            messageKeyClone = try cloneResult.unwrap()
            _ = SodiumInterop.secureWipe(&messageKeyBytes)
            
            let peerBundleResult = connectSession!.getPeerBundle()
            guard peerBundleResult.isOk else {
                throw ShieldChainStepError("Failed to get peer bundle: \(try peerBundleResult.unwrapErr())")
            }
            
            let peerBundle = try peerBundleResult.unwrap()
            
            let localId = ecliptixSystemIdentityKeys.identityX25519PublicKey
            let peerId = peerBundle.identityX25519
            var ad = localId + peerId
            debugPrint("[ShieldPro][Encrypt] Associated Data: \(ad.hexEncodedString())")
            
            var clonedKeyMaterial = Data(repeating: 0, count: Constants.aesKeySize)
            
            defer {
                _ = SodiumInterop.secureWipe(&clonedKeyMaterial)
            }

            _ = messageKeyClone!.readKeyMaterial(into: &clonedKeyMaterial)
            debugPrint("[ShieldPro][Encrypt] Ecryption Key: \(clonedKeyMaterial.hexEncodedString())")
            
            let encryptValues = try AesGcmService.encryptAllocating(
                key: clonedKeyMaterial,
                nonce: nonce,
                plaintext: plainPayload,
                associatedData: ad)
            ciphertext = encryptValues.ciphertext
            tag = encryptValues.tag
            debugPrint("[ShieldPro][Encrypt] Ciphertext: \(ciphertext!.hexEncodedString())")
            debugPrint("[ShieldPro][Encrypt] Tag: \(tag!.hexEncodedString())")
            
            let ciphertextAndTag = (ciphertext!) + (tag!)
            debugPrint("[ShieldPro][Encrypt] Ciphertext+Tag: \(ciphertextAndTag.hexEncodedString())")
            
            debugPrint("[ShieldPro][Encrypt] Nonce: \(nonce.hexEncodedString())")
            
            var payload = Ecliptix_Proto_CipherPayload()
            payload.requestID = Helpers.generateRandomUInt32(excludeZero: true)
            payload.nonce = nonce
            payload.ratchetIndex = messageKeyClone!.index
            payload.cipher = ciphertextAndTag
            payload.createdAt = Self.getProtoTimestamp()
            payload.dhPublicKey = newSenderDhPublicKey ?? Data()
            
            debugPrint("[ShieldPro] Outbound message prepared with Ratchet Index: \(messageKeyClone!.index)")
            return payload
        } catch {
            throw error
        }
    }

    
    func processInboundMessage(
        sessionId: UInt32,
        exchangeType: Ecliptix_Proto_PubKeyExchangeType,
        cipherPayloadProto: Ecliptix_Proto_CipherPayload
    ) throws -> Data {
        debugPrint("[ShieldPro] Processing inbound message for session \(sessionId) (\(exchangeType)), Ratchet Index: \(cipherPayloadProto.ratchetIndex)")

        var messageKeyBytes: Data?
        var plaintext: Data?
        var messageKeyClone: ShieldMessageKey?

        defer {
            _ = SodiumInterop.secureWipe(&messageKeyBytes)
            messageKeyClone?.dispose()
        }

        do {
            var receivedDhKey = cipherPayloadProto.dhPublicKey.isEmpty ? nil : cipherPayloadProto.dhPublicKey
            
            if receivedDhKey != nil {
                let currentPeerDhResult = connectSession!.getCurrentPeerDhPublicKey()
                if currentPeerDhResult.isOk {
                    let currentPeerDh = try currentPeerDhResult.unwrap()
                    debugPrint("[ShieldPro][Decrypt] Received DH Key: \(receivedDhKey!.hexEncodedString())")
                    debugPrint("[ShieldPro][Decrypt] Current Peer DH Key: \(currentPeerDh!.hexEncodedString())")

                    if receivedDhKey != currentPeerDh {
                        debugPrint("[ShieldPro] Performing DH ratchet due to new peer DH key.")
                        let ratchetResult = connectSession!.performReceivingRatchet(receivedDhKey: receivedDhKey!)
                        guard ratchetResult.isOk else {
                            throw ShieldChainStepError("Fialied to perform DH ratchet: \(try ratchetResult.unwrapErr())")
                        }
                    }
                }
            }

            debugPrint("[ShieldPro][Decrypt] Ciphertext+Tag: \(cipherPayloadProto.cipher.hexEncodedString())")
            debugPrint("[ShieldPro][Decrypt] Nonce: \(cipherPayloadProto.nonce.hexEncodedString())")

            let indexd = cipherPayloadProto.ratchetIndex
            let messageKeyResult = connectSession!.processReceivedMessage(receivedIndex: cipherPayloadProto.ratchetIndex, receivedDhPublicKeyBytes: &receivedDhKey)
            
            guard messageKeyResult.isOk else {
                throw ShieldChainStepError("Failed to process received message: \(try messageKeyResult.unwrapErr())")
            }
            
            let originalMessageKey = try messageKeyResult.unwrap()

            messageKeyBytes = Data(count: Constants.aesKeySize)
            _ = originalMessageKey.readKeyMaterial(into: &messageKeyBytes!)
            debugPrint("[ShieldPro][Decrypt] Message Key: \(messageKeyBytes!.hexEncodedString())")

            let cloneResult = ShieldMessageKey.new(index: originalMessageKey.index, keyMaterial: &messageKeyBytes!)
            guard cloneResult.isOk else {
                throw ShieldChainStepError("Failed to clone message key for decryption: \(try cloneResult.unwrapErr())")
            }
            messageKeyClone = try cloneResult.unwrap()
            debugPrint("[ShieldPro] Processed Key Index: \(messageKeyClone!.index)")

            let peerBundleResult = connectSession!.getPeerBundle()
            guard peerBundleResult.isOk else {
                throw ShieldChainStepError("Failed to get peer bundle: \(try peerBundleResult.unwrapErr())")
            }
            let peerBundle = try peerBundleResult.unwrap()
            
            let senderId = peerBundle.identityX25519
            let receiverId = ecliptixSystemIdentityKeys.identityX25519PublicKey
            var ad = senderId + receiverId
            print("[ShieldPro][Decrypt] Associated Data: \(ad.hexEncodedString())")

            var clonedKeyMaterial = Data(count: Constants.aesKeySize)
            defer {
                _ = SodiumInterop.secureWipe(&clonedKeyMaterial)
                _ = SodiumInterop.secureWipe(&plaintext)
                _ = SodiumInterop.secureWipe(&ad)
            }

            _ = messageKeyClone!.readKeyMaterial(into: &clonedKeyMaterial)
            debugPrint("[ShieldPro][Decrypt] Decryption Key: \(clonedKeyMaterial.hexEncodedString())")

            let fullCipherData = cipherPayloadProto.cipher
            let cipherLength = fullCipherData.count - Constants.aesGcmTagSize
            let cipherOnly = fullCipherData.prefix(cipherLength)
            let tagData = fullCipherData.dropFirst(cipherLength)

            plaintext = try AesGcmService.decryptAllocating(
                key: clonedKeyMaterial,
                nonce: cipherPayloadProto.nonce,
                ciphertext: cipherOnly,
                tag: tagData,
                associatedData: ad)
            debugPrint("[ShieldPro][Decrypt] Plaintext: \(plaintext!.hexEncodedString())")

            let plaintextCopy = plaintext!
            
            debugPrint("[ShieldPro][Decrypt] Returning plaintext copy: \(plaintextCopy.hexEncodedString())")
            
            return plaintextCopy
        } catch {
            throw error
        }
    }

    
//    func closeSession() {
//        if let session = connectSession {
//            // Тут можна додати очищення або безпечне знищення даних, якщо потрібно
//            
//            // Припустимо, що connectSession має свій метод для закриття сесії
//            session.dispose() // Якщо такого методу немає, додай його в ConnectSession
//
//            connectSession = nil
//        } else {
//            debugPrint("[ShieldPro] No active session to close.")
//        }
//    }

    
    private static func getProtoTimestamp() -> Google_Protobuf_Timestamp {
        let now = Date()
        let timestamp = Google_Protobuf_Timestamp.with {
            $0.seconds = Int64(now.timeIntervalSince1970)
            $0.nanos = Int32((now.timeIntervalSince1970 - floor(now.timeIntervalSince1970)) * 1_000_000_000)
        }
        return timestamp
    }
}
