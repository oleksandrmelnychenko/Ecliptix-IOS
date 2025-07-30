//
//  OpaqueClientAuthentication.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 01.07.2025.
//

import Foundation
import OpenSSL



enum OpaqueClientAuthentication {
    static func createSignInFinalizationContext(
        phoneNumber: String,
        passwordData: Data,
        signInResponse: Ecliptix_Proto_Membership_OpaqueSignInInitResponse,
        blind: UnsafePointer<BIGNUM>,
        staticPublicKeyPoint: OpaquePointer,
        staticPublicKey: Data,
        group: OpaquePointer
    ) -> Result<SignInFinalizationContext, OpaqueFailure> {
        
        OpaqueHashingUtils.recoverOprfKey(oprfResponse: signInResponse.serverOprfResponse, blind: blind, group: group)
            .flatMap { oprfKey in
                EVPCryptoUtils.deriveKey(
                    ikm: oprfKey,
                    salt: nil,
                    info: OpaqueConstants.credentialKeyInfo,
                    outputLength: OpaqueConstants.defaultKeyLength
                ).flatMap { credentialKey in
                    
                    guard signInResponse.registrationRecord.count >= OpaqueConstants.ecCompressedPointLength else {
                        return .failure(.invalidInput("Invalid registration record: too short"))
                    }

                    let clientStaticPublicKeyBytes = signInResponse.registrationRecord.prefix(OpaqueConstants.ecCompressedPointLength)
                    let envelope = signInResponse.registrationRecord.dropFirst(OpaqueConstants.ecCompressedPointLength)
                    
                    return deriveClientStaticPrivateKey(
                        envelope: envelope,
                        credentialKey: credentialKey,
                        associatedData: passwordData
                    ).flatMap { clientStaticPrivateKeyBN in
                        
                        ECPointUtils.generateKeyPair(group: group).flatMap { keyPair in
                            ECPointUtils.withBnCtx { ctx in
                                defer {
                                    BN_free(clientStaticPrivateKeyBN)
                                    keyPair.free()
                                }

                                return ECPointUtils.decodeCompressedPoint(signInResponse.serverEphemeralPublicKey, group: group, ctx: ctx)
                                    .flatMap { serverEphPoint in
                                        OpaqueAke.performClientAke(
                                            ephPrivateKey: keyPair.privateKey,
                                            statPrivateKey: clientStaticPrivateKeyBN,
                                            statSPub: staticPublicKeyPoint,
                                            ephSPub: serverEphPoint,
                                            group: group
                                        )
                                        .flatMap { ake in
                                            ECPublicKeyUtils.compressPoint(keyPair.publicKey, group: group, ctx: ctx)
                                                .flatMap { clientEphemeralPubKey in
                                                    
                                                    buildTranscriptHash(
                                                        phoneNumber: phoneNumber,
                                                        serverOprfResponse: signInResponse.serverOprfResponse,
                                                        clientStaticPublicKey: clientStaticPublicKeyBytes,
                                                        clientEphemeralPublicKey: clientEphemeralPubKey,
                                                        serverStaticPublicKey: staticPublicKey,
                                                        serverEphemeralPublicKey: signInResponse.serverEphemeralPublicKey
                                                    ).flatMap { transcriptHash in
                                                        
                                                        deriveFinalKeys(akeResult: ake, transcriptHash: transcriptHash)
                                                            .map { sessionKeys in
                                                                SignInFinalizationContext(
                                                                    clientEphemeralPublicKey: clientEphemeralPubKey,
                                                                    sessionKeys: sessionKeys,
                                                                    transcriptHash: transcriptHash
                                                                )
                                                            }
                                                    }
                                                }
                                        }
                                    }
                            }
                        }
                    }
                }
            }
    }

    
    private static func deriveFinalKeys(
        akeResult: Data,
        transcriptHash: Data
    ) -> Result<SessionKeys, OpaqueFailure> {
        return EVPCryptoUtils.hkdfExtract(ikm: akeResult, salt: OpaqueConstants.akeSalt)
            .flatMap { prk in
                var infoBuffer = Data(count: OpaqueConstants.sessionKeyInfo.count + transcriptHash.count)
                infoBuffer.replaceSubrange(OpaqueConstants.sessionKeyInfo.count..<infoBuffer.count, with: transcriptHash)

                // sessionKey
                infoBuffer.replaceSubrange(0..<OpaqueConstants.sessionKeyInfo.count, with: OpaqueConstants.sessionKeyInfo)
                return EVPCryptoUtils.hkdfExpand(prk: prk, info: infoBuffer, outputLength: OpaqueConstants.macKeyLength)
                    .flatMap { sessionKey in

                        // clientMacKey
                        infoBuffer.replaceSubrange(0..<OpaqueConstants.clientMacKeyInfo.count, with: OpaqueConstants.clientMacKeyInfo)
                        return EVPCryptoUtils.hkdfExpand(prk: prk, info: infoBuffer, outputLength: OpaqueConstants.macKeyLength)
                            .flatMap { clientMacKey in

                                // serverMacKey
                                infoBuffer.replaceSubrange(0..<OpaqueConstants.serverMacKeyInfo.count, with: OpaqueConstants.serverMacKeyInfo)
                                return EVPCryptoUtils.hkdfExpand(prk: prk, info: infoBuffer, outputLength: OpaqueConstants.macKeyLength)
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
}
