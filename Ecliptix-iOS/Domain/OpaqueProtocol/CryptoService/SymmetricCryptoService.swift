//
//  SymmetricCryptoService.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 29.07.2025.
//

import Foundation
import OpenSSL

struct SymmetricCryptoService {
    static func encrypt(plaintext: Data, key: Data, associatedData: Data?) -> Result<Data, OpaqueFailure> {
        let operation: CipherOperation = .encrypt
        
        return CryptoUtils.validateKeyLength(key)
            .flatMap { _ in
                CryptoUtils.withCipherCtx(operation: operation) { ctx in
                    let nonce = CryptoUtils.generateNonce()

                    return CryptoUtils.initGCM(ctx: ctx, key: key, nonce: nonce, operation: operation)
                        .flatMap { _ -> Result<Unit, OpaqueFailure> in
                            if let aad = associatedData {
                                return CryptoUtils.processAAD(ctx: ctx, aad: aad, operation: operation)
                            }
                            return .success(.value)
                        }
                        .flatMap { _ in
                            CryptoUtils.encryptPayload(ctx: ctx, plaintext: plaintext)
                        }
                        .flatMap { (ciphertext, cipherLen) in
                            var mutableCiphertext = ciphertext

                            return CryptoUtils.encryptFinal(ctx: ctx, ciphertext: &mutableCiphertext, cipherLen: cipherLen)
                                .flatMap { finalLen in
                                    CryptoUtils.getEncryptionTag(ctx: ctx)
                                        .map { tag in
                                            var output = Data()
                                            output.append(nonce)
                                            output.append(mutableCiphertext.prefix(Int(cipherLen + finalLen)))
                                            output.append(tag)
                                            return output
                                        }
                                }
                        }
                }
        }
    }
    
    static func decrypt(ciphertextWithNonce: Data, key: Data, associatedData: Data?) -> Result<Data, OpaqueFailure> {
        let operation: CipherOperation = .decrypt
        
        return CryptoUtils.validateKeyLength(key)
            .flatMap { _ in
                guard ciphertextWithNonce.count >= OpaqueConstants.aesGcmNonceLengthBytes + OpaqueConstants.aesGcmTagLengthBytes else {
                    return .failure(.decryptFailed(CryptoFailureMessages.ciphertextTooShort))
                }
                
                let nonce = ciphertextWithNonce.prefix(OpaqueConstants.aesGcmNonceLengthBytes)
                let tag = ciphertextWithNonce.suffix(OpaqueConstants.aesGcmTagLengthBytes)
                let ciphertext = ciphertextWithNonce
                    .dropFirst(OpaqueConstants.aesGcmNonceLengthBytes)
                    .dropLast(OpaqueConstants.aesGcmTagLengthBytes)
                
                return CryptoUtils.withCipherCtx(operation: operation) { ctx in
                    CryptoUtils.initGCM(ctx: ctx, key: key, nonce: nonce, operation: operation)
                        .flatMap { _ -> Result<Unit, OpaqueFailure> in
                            if let aad = associatedData {
                                return CryptoUtils.processAAD(ctx: ctx, aad: aad, operation: operation)
                            }
                            return .success(.value)
                        }
                        .flatMap { _ in
                            CryptoUtils.decryptPayload(ctx: ctx, ciphertext: ciphertext)
                        }
                        .flatMap { (plaintext, totalLen) in
                            CryptoUtils.setDecryptionTag(ctx: ctx, tag: tag)
                                .flatMap { _ in
                                    var mutabelPlaintext = plaintext
                                    return CryptoUtils.finalizeDecryption(ctx: ctx, plaintext: &mutabelPlaintext, totalLen: totalLen)
                                }
                        }
                }
            }
    }
}
