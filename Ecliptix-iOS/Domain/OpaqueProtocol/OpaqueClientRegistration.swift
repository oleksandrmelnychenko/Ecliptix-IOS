//
//  OpaqueClientRegistration.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 01.07.2025.
//

import Foundation
import OpenSSL

enum OpaqueClientRegistration {
    static func createRegistrationRecord(
        password: Data,
        oprfResponse: Data,
        blind: UnsafePointer<BIGNUM>,
        group: OpaquePointer
    ) -> Result<Data, OpaqueFailure> {
        return OpaqueHashingUtils.recoverOprfKey(oprfResponse: oprfResponse, blind: blind, group: group)
                .flatMap { oprfKey in
                    EVPCryptoUtils.deriveKey(
                        ikm: oprfKey,
                        salt: nil,
                        info: OpaqueConstants.credentialKeyInfo,
                        outputLength: OpaqueConstants.defaultKeyLength
                    )
                }
                .flatMap { credentialKey in
                    ECPointUtils.generateKeyPair(group: group)
                        .flatMap { keyPair in
                            ECPointUtils.withBnCtx { ctx in
                                defer {
                                    keyPair.free()
                                }
                                
                                let privKeyResult = exportPrivateKey(keyPair.privateKey)
                                let pubKeyResult = ECPublicKeyUtils.compressPoint(keyPair.publicKey, group: group, ctx: ctx)

                                return privKeyResult
                                    .flatMap { privKey in pubKeyResult
                                            .flatMap { pubKey in
                                                SymmetricCryptoService.encrypt( plaintext: privKey, key: credentialKey, associatedData: password)
                                                    .map { envelope in
                                                        var record = Data()
                                                        record.append(pubKey)
                                                        record.append(envelope)
                                                        return record
                                                    }
                                            }
                                    }
                            }
                        }
                }
    }
    
    private static func exportPrivateKey(_ bn: UnsafeMutablePointer<BIGNUM>) -> Result<Data, OpaqueFailure> {
        let length = (BN_num_bits(bn) + 7) / 8
        var buffer = [UInt8](repeating: 0, count: Int(length))
        BN_bn2bin(bn, &buffer)
        return .success(Data(buffer))
    }
}
