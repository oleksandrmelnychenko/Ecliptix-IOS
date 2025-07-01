//
//  OpaqueClientAuthentication.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 01.07.2025.
//

import Foundation
import OpenSSL

enum OpaqueClientAuthentication {
    static func createSignInFinalizationRequest(
        phoneNumber: String,
        passwordData: Data,
        signInResponse: Ecliptix_Proto_Membership_OpaqueSignInInitResponse,
        blind: UnsafePointer<BIGNUM>,
        staticPublicKeyPoint: OpaquePointer,
        staticPublicKey: Data,
        group: OpaquePointer
    ) -> Result<(Ecliptix_Proto_Membership_OpaqueSignInFinalizeRequest, Data, Data, Data), OpaqueFailure> {
        do {
            // 1. OPRF
            guard case let .success(oprfKey) = OpaqueCryptoUtilities.recoverOprfKey(oprfResponse: signInResponse.serverOprfResponse, blind: blind, group: group) else {
                return .failure(.invalidInput("Invalid OPRF response"))
            }

            // 2. Credential Key
            let credentialKey = OpaqueCryptoUtilities.deriveKey(
                ikm: oprfKey,
                salt: nil,
                info: OpaqueConstants.credentialKeyInfo,
                outputLength: OpaqueConstants.defaultKeyLength
            )

            // 3. Validate registration record
            guard signInResponse.registrationRecord.count >= OpaqueConstants.compressedPublicKeyLength else {
                return .failure(.invalidInput("Invalid registration record: too short."))
            }

            let clientStaticPublicKeyBytes = signInResponse.registrationRecord.prefix(OpaqueConstants.compressedPublicKeyLength)
            let envelope = signInResponse.registrationRecord.dropFirst(OpaqueConstants.compressedPublicKeyLength)

            // 4. Static private key decryption
            let staticKeyResult = deriveClientStaticPrivateKey(
                envelope: envelope,
                credentialKey: credentialKey,
                associatedData: passwordData
            )
            guard case let .success(clientStaticPrivateKeyBN) = staticKeyResult else {
                return staticKeyResult.map { _ in fatalError() }
            }

            // 5. Generate ephemeral key pair
            let ephKeyResult = createClientEphemeralKeyPair(group: group)
            guard case let .success((ephPrivateBN, ephPublicPoint)) = ephKeyResult else {
               return ephKeyResult.map { _ in fatalError() }
            }
            
            defer {
                BN_free(ephPrivateBN)
                EC_POINT_free(ephPublicPoint)
            }
            
            // 6. Decode server ephemeral public key
            let ctx = BN_CTX_new()
            guard let ctx else {
                return .failure(.invalidInput("Failed to allocate BN_CTX"))
            }
            defer { BN_CTX_free(ctx) }
            
            guard case let .success(ephSPubPoint) = OpaqueCryptoUtilities.decodeCompressedPoint(signInResponse.serverEphemeralPublicKey, group: group, ctx: ctx) else {
                return .failure(.invalidInput("Failed to decode server ephemeral key"))
            }
            
            // 7. Perform AKE
            let akeResult = OpaqueAke.performClientAke(
                ephPrivateKey: ephPrivateBN,
                statPrivateKey: clientStaticPrivateKeyBN,
                statSPub: staticPublicKeyPoint,
                ephSPub: ephSPubPoint,
                group: group
            )
            guard case let .success(ake) = akeResult else {
                return akeResult.map { _ in fatalError() }
            }
            
            // 8. Compress client ephemeral public key
            var clientEphemeralPubKey = Data(repeating: 0, count: 33)
            let written = clientEphemeralPubKey.withUnsafeMutableBytes {
                EC_POINT_point2oct(
                    group,
                    ephPublicPoint,
                    POINT_CONVERSION_COMPRESSED,
                    $0.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    33,
                    nil
                )
            }

            guard written == 33 else {
                return .failure(.pointCompressionFailed("Invalid ephemeral public key size"))
            }

            // 9. Build transcript hash
            let transcriptResult = buildTranscriptHash(
                phoneNumber: phoneNumber,
                serverOprfResponse: signInResponse.serverOprfResponse,
                clientStaticPublicKey: clientStaticPublicKeyBytes,
                clientEphemeralPublicKey: clientEphemeralPubKey,
                serverStaticPublicKey: staticPublicKey,
                serverEphemeralPublicKey: signInResponse.serverEphemeralPublicKey
            )
            guard case let .success(transcriptHash) = transcriptResult else {
                return transcriptResult.map { _ in fatalError() }
            }

            // 10. Derive final session/mac keys
            let keysResult = deriveFinalKeys(akeResult: ake, transcriptHash: transcriptHash)
            guard case let .success((sessionKey, clientMacKey, serverMacKey)) = keysResult else {
                return keysResult.map { _ in fatalError() }
            }

            // 11. MAC and finalize request
            let clientMac = OpaqueCryptoUtilities.createMac(key: clientMacKey, data: transcriptHash)

            let finalizeRequest = Self.buildFinalizeRequest(
                phoneNumber: phoneNumber,
                clientEphemeralPublicKey: clientEphemeralPubKey,
                clientMac: clientMac,
                serverStateToken: signInResponse.serverStateToken)
            
            return .success((finalizeRequest, sessionKey, serverMacKey, transcriptHash))
        } catch {
            return .failure(.invalidInput("Error during create sign in finalization request", inner: error))
        }
    }
    
    private static func deriveFinalKeys(akeResult: Data, transcriptHash: Data) -> Result<(sessionKey: Data, clientMacKey: Data, serverMacKey: Data), OpaqueFailure> {
        do {
            let prkResult = OpaqueCryptoUtilities.hkdfExtract(ikm: akeResult, salt: OpaqueConstants.akeSalt)

            guard case .success(let prk) = prkResult else {
                return .failure(try prkResult.unwrapErr())
            }

            var infoBuffer = Data(count: OpaqueConstants.sessionKeyInfo.count + transcriptHash.count)
            infoBuffer.replaceSubrange(OpaqueConstants.sessionKeyInfo.count..<infoBuffer.count, with: transcriptHash)
            
            infoBuffer.replaceSubrange(0..<OpaqueConstants.sessionKeyInfo.count, with: OpaqueConstants.sessionKeyInfo)
            let sessionKey = OpaqueCryptoUtilities.hkdfExpand(prk: prk, info: infoBuffer, outputLength: OpaqueConstants.macKeyLength)

            infoBuffer.replaceSubrange(0..<OpaqueConstants.clientMacKeyInfo.count, with: OpaqueConstants.clientMacKeyInfo)
            let clientMacKey = OpaqueCryptoUtilities.hkdfExpand(prk: prk, info: infoBuffer, outputLength: OpaqueConstants.macKeyLength)

            infoBuffer.replaceSubrange(0..<OpaqueConstants.serverMacKeyInfo.count, with: OpaqueConstants.serverMacKeyInfo)
            let serverMacKey = OpaqueCryptoUtilities.hkdfExpand(prk: prk, info: infoBuffer, outputLength: OpaqueConstants.macKeyLength)

            return .success((sessionKey, clientMacKey, serverMacKey))
        } catch {
            return .failure(error as! OpaqueFailure)
        }
    }
    
    private static func deriveClientStaticPrivateKey(
        envelope: Data,
        credentialKey: Data,
        associatedData: Data
    ) -> Result<UnsafePointer<BIGNUM>, OpaqueFailure> {
        let decrypted = OpaqueCryptoUtilities.decrypt(
            ciphertextWithNonce: envelope,
            key: credentialKey,
            associatedData: associatedData
        )

        guard case let .success(data) = decrypted else {
            return .failure(.decryptFailed("Failed to decrypt envelope"))
        }

        guard let bn = BN_bin2bn([UInt8](data), Int32(data.count), nil) else {
            return .failure(.invalidInput("Failed to create private key BIGNUM"))
        }

        return .success(bn)
    }

    private static func createClientEphemeralKeyPair(
        group: OpaquePointer
    ) -> Result<(UnsafeMutablePointer<BIGNUM>, OpaquePointer), OpaqueFailure> {
        guard let (priv, pub) = OpaqueCryptoUtilities.generateKeyPair(group: group) else {
            return .failure(.invalidInput("Ephemeral key generation failed"))
        }

        return .success((priv, pub))
    }
    
    private static func buildTranscriptHash(
        phoneNumber: String,
        serverOprfResponse: Data,
        clientStaticPublicKey: Data,
        clientEphemeralPublicKey: Data,
        serverStaticPublicKey: Data,
        serverEphemeralPublicKey: Data
    ) -> Result<Data, OpaqueFailure> {
        TranscriptHasher.hash(
            phoneNumber: phoneNumber,
            oprfResponse: serverOprfResponse,
            clientStaticPublicKey: clientStaticPublicKey,
            clientEphemeralPublicKey: clientEphemeralPublicKey,
            serverStaticPublicKey: serverStaticPublicKey,
            serverEphemeralPublicKey: serverEphemeralPublicKey
        )
    }
    
    private static func buildFinalizeRequest(
        phoneNumber: String,
        clientEphemeralPublicKey: Data,
        clientMac: Data,
        serverStateToken: Data
    ) -> Ecliptix_Proto_Membership_OpaqueSignInFinalizeRequest {
        
        var request = Ecliptix_Proto_Membership_OpaqueSignInFinalizeRequest()
        request.phoneNumber = phoneNumber
        request.clientEphemeralPublicKey = clientEphemeralPublicKey
        request.clientMac = clientMac
        request.serverStateToken = serverStateToken
        return request
    }
}
