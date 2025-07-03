//
//  EcliptixProtocolSystem.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 29.05.2025.
//

import Foundation
import SwiftProtobuf

public class EcliptixProtocolSystem {
    private var protocolConnection: EcliptixProtocolConnection?
    private let ecliptixSystemIdentityKeys: EcliptixSystemIdentityKeys

    init(ecliptixSystemIdentityKeys: EcliptixSystemIdentityKeys) {
        self.ecliptixSystemIdentityKeys = ecliptixSystemIdentityKeys
    }
    
    func getIdentityKeys() -> EcliptixSystemIdentityKeys {
        self.ecliptixSystemIdentityKeys
    }
    
    func beginDataCenterPubKeyExchange(
        connectId: UInt32,
        exchangeType: Ecliptix_Proto_PubKeyExchangeType
    ) throws -> Result<Ecliptix_Proto_PubKeyExchange, EcliptixProtocolFailure> {
        self.ecliptixSystemIdentityKeys.generateEphemeralKeyPair()
        
        return ecliptixSystemIdentityKeys.createPublicBundle()
            .flatMap { bundle in EcliptixProtocolConnection.create(connectId: connectId, isInitiator: true)
                .flatMap { session in
                    self.protocolConnection = session
                    return session.getCurrentSenderDhPublicKey()
                        .map { dhPublicKey in
                            var pubKeyExchange = Ecliptix_Proto_PubKeyExchange()
                            pubKeyExchange.state = .init_
                            pubKeyExchange.ofType = exchangeType
                            pubKeyExchange.payload = try! bundle.toProtobufExchange().serializedData()
                            pubKeyExchange.initialDhPublicKey = Data(dhPublicKey!)
                            return pubKeyExchange
                    }
                }
            }
    }

    
    func processAndRespondToPubKeyExchange(connectId: UInt32, peerInitialMessageProto: inout Ecliptix_Proto_PubKeyExchange) throws -> Result<Ecliptix_Proto_PubKeyExchange, EcliptixProtocolFailure> {
        
        var rootKeyHandle: SodiumSecureMemoryHandle? = nil
        
        defer {
            rootKeyHandle?.dispose()
        }
        
        do {
            return Result<Unit, EcliptixProtocolFailure>
                .validate(.value, predicate: { _ in peerInitialMessageProto.state == .init_ }, error: .invalidInput("Expected peer message state to be Init, but was \(peerInitialMessageProto.state)."))
                .flatMap { _ in
                    Result<Ecliptix_Proto_PublicKeyBundle, EcliptixProtocolFailure>.Try {
                        try Helpers.parseFromBytes(Ecliptix_Proto_PublicKeyBundle.self, data: peerInitialMessageProto.payload)
                    }.mapError { error in
                        .decode("Failed to parse peer public key bundle from protobuf.", inner: error)
                    }
                }
                .flatMap { proto in PublicKeyBundle.fromProtobufExchange(proto) }
                .flatMap { peerBundle in
                    EcliptixSystemIdentityKeys.verifyRemoteSpkSignature(remoteIdentityEd25519: peerBundle.identityEd25519, remoteSpkPublic: peerBundle.signedPreKeyPublic, remoteSpkSignature: peerBundle.signedPreKeySignature)
                        .flatMap { spkValid in
                            Result<Unit, EcliptixProtocolFailure>.validate(Unit.value, predicate: { _ in spkValid }, error: .handshake("SPK signature validation failed."))
                        }
                        .flatMap { _ in
                            self.ecliptixSystemIdentityKeys.generateEphemeralKeyPair()
                            return self.ecliptixSystemIdentityKeys.createPublicBundle()
                        }
                        .flatMap { localBundle in EcliptixProtocolConnection.create(connectId: connectId, isInitiator: false)
                                .flatMap { session in
                                    self.protocolConnection = session
                                    return self.ecliptixSystemIdentityKeys.calculateSharedSecretAsRecipient(
                                        remoteIdentityPublicKeyX: peerBundle.identityX25519,
                                        remoteEphemeralPublicKeyX: peerBundle.ephemeralX25519!,
                                        usedLocalOpkId: peerBundle.oneTimePreKeys.first?.preKeyId,
                                        info: Constants.x3dhInfo)
                                    .flatMap { derivedKeyHandle in
                                        rootKeyHandle = derivedKeyHandle
                                        return Self.readAndWipeSecureHandle(handle: derivedKeyHandle, size: Constants.x25519KeySize)
                                    }
                                    .flatMap { rootKeyBytes in
                                        var rootKeyBytesCopy = rootKeyBytes
                                        return session.finalizeChainAndDhKeys(initialRootKey: &rootKeyBytesCopy, initialPeerDhPublicKey: &peerInitialMessageProto.initialDhPublicKey)
                                    }
                                    .flatMap { _ in session.setPeerBundle(peerBundle) }
                                    .flatMap { _ in session.setConnectionState(.complete) }
                                    .flatMap { _ in session.getCurrentSenderDhPublicKey() }
                                    .map { dhPublicKey in
                                        var pubKeyExchange = Ecliptix_Proto_PubKeyExchange()
                                        pubKeyExchange.state = .pending
                                        pubKeyExchange.ofType = peerInitialMessageProto.ofType
                                        pubKeyExchange.payload = try! localBundle.toProtobufExchange().serializedData()
                                        pubKeyExchange.initialDhPublicKey = Data(dhPublicKey!)
                                        return pubKeyExchange
                                    }
                                }
                        }
                }
        } catch {
            debugPrint("[ShieldPro] Error in processAndRespondToPubKeyExchange for session \(connectId): \(error)")
            throw error
        }
    }

    func completeDataCenterPubKeyExchange(peerMessage: inout Ecliptix_Proto_PubKeyExchange) throws {
        var rootKeyHandle: SodiumSecureMemoryHandle? = nil
        
        defer {
            rootKeyHandle?.dispose()
        }
        
        do {
            Result<Ecliptix_Proto_PublicKeyBundle, EcliptixProtocolFailure>.Try {
                try Helpers.parseFromBytes(Ecliptix_Proto_PublicKeyBundle.self, data: peerMessage.payload)
            }.mapError { error in
                .decode("Failed to parse peer public key bundle from protobuf.", inner: error)
            }
            .flatMap { proto in PublicKeyBundle.fromProtobufExchange(proto) }
            .flatMap { peerBundle in EcliptixSystemIdentityKeys.verifyRemoteSpkSignature(remoteIdentityEd25519: peerBundle.identityEd25519, remoteSpkPublic: peerBundle.signedPreKeyPublic, remoteSpkSignature: peerBundle.signedPreKeySignature)
                    .flatMap { spkValid in Result<Unit, EcliptixProtocolFailure>.validate(Unit.value, predicate: { _ in spkValid }, error: .handshake("SPK signature validation failed during completion.")) }
                    .flatMap { _ in self.ecliptixSystemIdentityKeys.x3dhDeriveSharedSecret(remoteBundle: peerBundle, info: Constants.x3dhInfo) }
                    .flatMap { derivedKeyHandle in
                        rootKeyHandle = derivedKeyHandle
                        return Self.readAndWipeSecureHandle(handle: derivedKeyHandle, size: Constants.x25519KeySize)
                    }
                    .flatMap { rootKeyBytes in
                        var rootKeyBytesCopy = rootKeyBytes
                        return self.protocolConnection!.finalizeChainAndDhKeys(initialRootKey: &rootKeyBytesCopy, initialPeerDhPublicKey: &peerMessage.initialDhPublicKey)
                    }
                    .flatMap { _ in self.protocolConnection!.setPeerBundle(peerBundle) }
                    .flatMap { _ in self.protocolConnection!.setConnectionState(.complete) }
            }
        } catch {
            debugPrint("Unexpected error in completeDataCenterPubKeyExchange: \(error)")
        }
    }

    
    func produceOutboundMessage(plainPayload: Data) throws -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {

        var messageKeyClone: EcliptixMessageKey? = nil

        defer {
            messageKeyClone?.dispose()
        }
        
        do {
            return self.protocolConnection!.prepareNextSendMessage()
                .flatMap { prep in self.protocolConnection!.generateNextNonce()
                        .flatMap { nonce in getOptionalSenderDhKey(include: prep.includeDhKey)
                                .flatMap { newSenderDhPublicKey in Self.cloneMessageKey(key: prep.messageKey)
                                        .flatMap { clonedKey in
                                            messageKeyClone = clonedKey
                                            return self.protocolConnection!.getPeerBundle()
                                        }
                                        .flatMap { peerBundle in
                                            let ad = Self.createAssociatedData(self.ecliptixSystemIdentityKeys.identityX25519PublicKey, peerBundle.identityX25519)
                                            return Self.encrypt(key: messageKeyClone!, nonce: nonce, plaintext: plainPayload, ad: ad)
                                        }
                                        .map { encrypted in
                                            var cipherPayload = Ecliptix_Proto_CipherPayload()
                                            cipherPayload.requestID = Helpers.generateRandomUInt32(excludeZero: true)
                                            cipherPayload.nonce = Data(nonce)
                                            cipherPayload.ratchetIndex = messageKeyClone!.index
                                            cipherPayload.cipher = Data(encrypted)
                                            cipherPayload.createdAt = Self.getProtoTimestamp()
                                            cipherPayload.dhPublicKey = newSenderDhPublicKey.count > 0 ? Data(newSenderDhPublicKey) : Data()
                                            return cipherPayload
                                        }
                                    
                                }
                    }
                    
                }
        } catch {
            throw error
        }
    }

    
    func processInboundMessage(cipherPayloadProto: Ecliptix_Proto_CipherPayload) throws -> Result<Data, EcliptixProtocolFailure> {
        
        var messageKeyClone: EcliptixMessageKey?

        defer {
            messageKeyClone?.dispose()
        }

        do {
            var receivedDhKey = cipherPayloadProto.dhPublicKey.count > 0 ? cipherPayloadProto.dhPublicKey : nil
            
            return performRatchetIfNeeded(receivedDhKey: receivedDhKey)
                .flatMap { _ in self.protocolConnection!.processReceivedMessage(receivedIndex: cipherPayloadProto.ratchetIndex, receivedDhPublicKeyBytes: &receivedDhKey)
                }
                .flatMap { key in Self.cloneMessageKey(key: key) }
                .flatMap { clonedKey in
                    messageKeyClone = clonedKey
                    return self.protocolConnection!.getPeerBundle()
                }
                .flatMap { peerBundle in
                    let ad = Self.createAssociatedData(peerBundle.identityX25519, self.ecliptixSystemIdentityKeys.identityX25519PublicKey)
                    return Self.decrypt(key: messageKeyClone!, payload: cipherPayloadProto, ad: ad)
                }
        } catch {
            throw error
        }
    }
    
    static func createFrom(keys: EcliptixSystemIdentityKeys, connection: EcliptixProtocolConnection) -> Result<EcliptixProtocolSystem, EcliptixProtocolFailure> {
        var system = EcliptixProtocolSystem(ecliptixSystemIdentityKeys: keys)
        system.protocolConnection = connection
        
        return .success(system)
    }
    
    func getConnection() throws -> EcliptixProtocolConnection {
        if self.protocolConnection == nil {
            throw EcliptixProtocolFailure.unexpectedError("Connection has not been established yet.")
        }
        
        return self.protocolConnection!
    }

    private func getOptionalSenderDhKey(include: Bool) -> Result<Data, EcliptixProtocolFailure> {
        return include
            ? self.protocolConnection!.getCurrentSenderDhPublicKey().map { k in k! }
            : .success(Data())
    }
    
    private func performRatchetIfNeeded(receivedDhKey: Data?) -> Result<Unit, EcliptixProtocolFailure> {
        if receivedDhKey == nil {
            return .success(.value)
        }
        
        return self.protocolConnection!.getCurrentPeerDhPublicKey()
            .flatMap { currentPeerDhKey in
                if currentPeerDhKey != nil && receivedDhKey != currentPeerDhKey {
                    return self.protocolConnection!.performReceivingRatchet(receivedDhKey: receivedDhKey!)
                }
                
                return .success(.value)
            }
    }
    
    private static func createAssociatedData(_ id1: Data, _ id2: Data) -> Data {
        let ad = id1 + id2
        return ad
    }
    
    private static func encrypt(key: EcliptixMessageKey, nonce: Data, plaintext: Data, ad: Data) -> Result<Data, EcliptixProtocolFailure> {
        var keyMaterial: Data? = nil
        do {
            keyMaterial = Data(count: Constants.aesKeySize)
            let readResult = key.readKeyMaterial(into: &keyMaterial!)
            if readResult.isErr {
                return .failure(try readResult.unwrapErr())
            }
            
            print("keyMaterial: \(keyMaterial!.hexEncodedString())")
            
            var encryptValues = try AesGcmService.encryptAllocating(key: keyMaterial!, nonce: nonce, plaintext: plaintext, associatedData: ad)
            let ciphertextAndTag = encryptValues.ciphertext + encryptValues.tag
                        
            _ = SodiumInterop.secureWipe(&encryptValues.ciphertext)
            _ = SodiumInterop.secureWipe(&encryptValues.tag)
            return .success(ciphertextAndTag)
        } catch {
            return .failure(.generic("AES-GCM encryption failed", inner: error))
        }
    }
    
    private static func decrypt(key: EcliptixMessageKey, payload: Ecliptix_Proto_CipherPayload, ad: Data) -> Result<Data, EcliptixProtocolFailure> {
        let fullCipher = payload.cipher
        let tagSize = Constants.aesGcmTagSize
        let cipherSize = fullCipher.count - tagSize
        
        guard cipherSize >= 0 else {
            return .failure(.bufferTooSmall("Received ciphertext length (\(fullCipher.count)) is smaller than the GCM tag size (\(tagSize))."))
        }
        
        var keyMaterial: Data? = nil
        var cipherOnlyBytes: Data? = nil
        var tagBytes: Data? = nil
        do {
            keyMaterial = Data(count: Constants.aesKeySize)
            let readResult = key.readKeyMaterial(into: &keyMaterial!)
            if readResult.isErr {
                return .failure(try readResult.unwrapErr())
            }
            
            cipherOnlyBytes = Data(count: cipherSize)
            cipherOnlyBytes = fullCipher.prefix(cipherSize)
            
            tagBytes = Data(count: tagSize)
            tagBytes = fullCipher.suffix(tagSize)
            
            print("keyMaterial: \(keyMaterial!.hexEncodedString())")
            
            let result = try AesGcmService.decryptAllocating(key: keyMaterial!, nonce: payload.nonce, ciphertext: cipherOnlyBytes!, tag: tagBytes!, associatedData: ad)
            
            return .success(result)
        } catch {
            return .failure(.generic("Unexpected error during AES-GCM decryption.", inner: error))
        }
    }
    
    private static func readAndWipeSecureHandle(handle: SodiumSecureMemoryHandle, size: Int) -> Result<Data, EcliptixProtocolFailure> {
        var buffer = Data(count: size)
        let t = buffer.withUnsafeMutableBytes { buffer in
            handle.read(into: buffer)
        }.map { _ in
            let copy = Data(buffer)
            _ = SodiumInterop.secureWipe(&buffer)
            return copy
        }.mapSodiumFailure()
        
        return t
    }

    private static func cloneMessageKey(key: EcliptixMessageKey) -> Result<EcliptixMessageKey, EcliptixProtocolFailure> {
        var keyMaterial = Data(count: Constants.aesKeySize)
        _ = key.readKeyMaterial(into: &keyMaterial)
        return EcliptixMessageKey.new(index: key.index, keyMaterial: &keyMaterial)
    }
    
    private static func getProtoTimestamp() -> Google_Protobuf_Timestamp {
        let now = Date()
        let timestamp = Google_Protobuf_Timestamp.with {
            $0.seconds = Int64(now.timeIntervalSince1970)
            $0.nanos = Int32((now.timeIntervalSince1970 - floor(now.timeIntervalSince1970)) * 1_000_000_000)
        }
        return timestamp
    }
}
