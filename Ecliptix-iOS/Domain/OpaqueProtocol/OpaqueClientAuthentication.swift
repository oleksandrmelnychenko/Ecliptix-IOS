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
    ) -> Result<SignInFinalizationContext, OpaqueFailure> {
        do {
            // 1. OPRF
            guard case let .success(oprfKey) = OpaqueCryptoUtilities.recoverOprfKey(oprfResponse: signInResponse.serverOprfResponse, blind: blind, group: group) else {
                return .failure(.invalidInput("Invalid OPRF response"))
            }

            // 2. Credential Key
            let credentialKeyResult = OpaqueCryptoUtilities.deriveKey(
                ikm: oprfKey,
                salt: nil,
                info: OpaqueConstants.credentialKeyInfo,
                outputLength: OpaqueConstants.defaultKeyLength
            )
            guard case let .success(credentialKey) = credentialKeyResult else {
                return .failure(try credentialKeyResult.unwrapErr())
            }

            
            // 3. Validate registration record
            guard signInResponse.registrationRecord.count >= OpaqueConstants.ecCompressedPointLength else {
                return .failure(.invalidInput("Invalid registration record: too short."))
            }

            let clientStaticPublicKeyBytes = signInResponse.registrationRecord.prefix(OpaqueConstants.ecCompressedPointLength)
            let envelope = signInResponse.registrationRecord.dropFirst(OpaqueConstants.ecCompressedPointLength)
            
            // 4. Static private key decryption
            let staticKeyResult = deriveClientStaticPrivateKey(
                envelope: envelope,
                credentialKey: credentialKey,
                associatedData: passwordData
            )
            guard case let .success(clientStaticPrivateKeyBN) = staticKeyResult else {
                return .failure(try staticKeyResult.unwrapErr())
            }
            
            // 5. Generate ephemeral key pair
            let ephKeyResult = ECPointUtils.generateKeyPair(group: group)
            guard case let .success((ephPrivateBN, ephPublicPoint)) = ephKeyResult else {
                return .failure(try ephKeyResult.unwrapErr())
            }
            print("Private ephemeral key: \(ephPrivateBN)")
            
            defer {
                BN_free(ephPrivateBN)
                EC_POINT_free(ephPublicPoint)
                BN_free(clientStaticPrivateKeyBN)
            }
            
            // 6. Decode server ephemeral public key
            let ctx = BN_CTX_new()
            guard let ctx else {
                return .failure(.invalidInput("Failed to allocate BN_CTX"))
            }
            defer { BN_CTX_free(ctx) }
            
            guard case let .success(ephSPubPoint) = ECPointUtils.decodeCompressedPoint(signInResponse.serverEphemeralPublicKey, group: group, ctx: ctx) else {
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
                return .failure(try akeResult.unwrapErr())
            }
            print("Ake bytes: \(Array(ake))")
            
            // 8. Compress client ephemeral public key
            let clientEphemeralPubKeyResult = ECPointUtils.compressPoint(ephPublicPoint, group: group, ctx: ctx)
            guard case let .success(clientEphemeralPubKey) = clientEphemeralPubKeyResult else {
                return .failure(try clientEphemeralPubKeyResult.unwrapErr())
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
                return .failure(try transcriptResult.unwrapErr())
            }

            // 10. Derive final session/mac keys
            let keysResult = deriveFinalKeys(akeResult: ake, transcriptHash: transcriptHash)
            guard case let .success(sessionKeys) = keysResult else {
                return .failure(try keysResult.unwrapErr())
            }

            // 11. MAC
//            let clientMac = try OpaqueCryptoUtilities.createMac(key: sessionKeys.clientMacKey, data: transcriptHash).unwrap()
//            
//            var request = Ecliptix_Proto_Membership_OpaqueSignInFinalizeRequest()
//            request.phoneNumber = phoneNumber
//            request.clientMac = clientMac
//            request.clientEphemeralPublicKey = clientEphemeralPubKey
//            request.serverStateToken = signInResponse.serverStateToken

            return .success(SignInFinalizationContext(
                clientEphemeralPublicKey: clientEphemeralPubKey,
                sessionKeys: sessionKeys,
                transcriptHash: transcriptHash)
            )
        } catch {
            return .failure(.invalidInput("Error during create sign in finalization request", inner: error))
        }
    }
    
    private static func deriveFinalKeys(
        akeResult: Data,
        transcriptHash: Data
    ) -> Result<SessionKeys, OpaqueFailure> {
        return OpaqueCryptoUtilities.hkdfExtract(ikm: akeResult, salt: OpaqueConstants.akeSalt)
            .flatMap { prk in
                var infoBuffer = Data(count: OpaqueConstants.sessionKeyInfo.count + transcriptHash.count)
                infoBuffer.replaceSubrange(OpaqueConstants.sessionKeyInfo.count..<infoBuffer.count, with: transcriptHash)

                // sessionKey
                infoBuffer.replaceSubrange(0..<OpaqueConstants.sessionKeyInfo.count, with: OpaqueConstants.sessionKeyInfo)
                return OpaqueCryptoUtilities.hkdfExpand(prk: prk, info: infoBuffer, outputLength: OpaqueConstants.macKeyLength)
                    .flatMap { sessionKey in

                        // clientMacKey
                        infoBuffer.replaceSubrange(0..<OpaqueConstants.clientMacKeyInfo.count, with: OpaqueConstants.clientMacKeyInfo)
                        return OpaqueCryptoUtilities.hkdfExpand(prk: prk, info: infoBuffer, outputLength: OpaqueConstants.macKeyLength)
                            .flatMap { clientMacKey in

                                // serverMacKey
                                infoBuffer.replaceSubrange(0..<OpaqueConstants.serverMacKeyInfo.count, with: OpaqueConstants.serverMacKeyInfo)
                                return OpaqueCryptoUtilities.hkdfExpand(prk: prk, info: infoBuffer, outputLength: OpaqueConstants.macKeyLength)
                                    .map { serverMacKey in
                                        SessionKeys(
                                            sessionKey: sessionKey,
                                            clientMacKey: clientMacKey,
                                            serverMacKey: serverMacKey
                                        )
                                    }
                            }
                    }
            }
    }
    
    private static func deriveClientStaticPrivateKey(
        envelope: Data,
        credentialKey: Data,
        associatedData: Data
    ) -> Result<UnsafeMutablePointer<BIGNUM>, OpaqueFailure> {
        return SymmetricCryptoService.decrypt(ciphertextWithNonce: envelope, key: credentialKey, associatedData: associatedData)
            .flatMap { data in
                guard let bn = BN_bin2bn([UInt8](data), Int32(data.count), nil) else {
                    return .failure(.invalidInput("Failed to create private key BIGNUM"))
                }
                return .success(bn)
            }
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
