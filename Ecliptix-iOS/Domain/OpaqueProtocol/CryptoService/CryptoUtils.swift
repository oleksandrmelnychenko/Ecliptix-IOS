//
//  CryptoUtils.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 29.07.2025.
//

import Foundation
import OpenSSL

enum CryptoUtils {
    static func validateKeyLength(_ key: Data) -> Result<Unit, OpaqueFailure> {
        key.count == OpaqueConstants.defaultKeyLength
            ? .success(.value)
            : .failure(.encryptFailed(CryptoFailureMessages.invalidKeyLength))
    }
    
    static func generateNonce() -> Data {
        Data((0..<OpaqueConstants.aesGcmNonceLengthBytes)
            .map { _ in UInt8.random(in: 0...255) })
    }

    static func encryptPayload(
        ctx: UnsafeMutablePointer<EVP_CIPHER_CTX>,
        plaintext: Data
    ) -> Result<(ciphertext: Data, cipherLen: Int32), OpaqueFailure> {
        var ciphertext = Data(count: plaintext.count)
        var cipherLen: Int32 = 0
        
        let success = plaintext.withUnsafeBytes { plainPtr in
            ciphertext.withUnsafeMutableBytes { cipherPtr in
                EVP_EncryptUpdate(
                    ctx,
                    cipherPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    &cipherLen,
                    plainPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    Int32(plaintext.count)
                ) == 1
            }
        }
        
        guard success else {
            return .failure(.encryptFailed(CryptoFailureMessages.encryptUpdateFailed))
        }
        
        return .success((ciphertext, cipherLen))
    }
    
    static func encryptFinal(
        ctx: UnsafeMutablePointer<EVP_CIPHER_CTX>,
        ciphertext: inout Data,
        cipherLen: Int32
    ) -> Result<Int32, OpaqueFailure> {
        var finalLen: Int32 = 0
        let success = ciphertext.withUnsafeMutableBytes {
            EVP_EncryptFinal_ex(
                ctx,
                $0.baseAddress?.assumingMemoryBound(to: UInt8.self).advanced(by: Int(cipherLen)),
                &finalLen
            ) == 1
        }

        return success
            ? .success(finalLen)
            : .failure(.encryptFailed(CryptoFailureMessages.encryptFinalFailed))
    }
    
    static func getEncryptionTag(
        ctx: UnsafeMutablePointer<EVP_CIPHER_CTX>
    ) -> Result<Data, OpaqueFailure> {
        var tagBytes = [UInt8](repeating: 0, count: OpaqueConstants.aesGcmTagLengthBytes)
        let success = EVP_CIPHER_CTX_ctrl(
            ctx,
            EVP_CTRL_GCM_GET_TAG,
            Int32(tagBytes.count),
            &tagBytes
        ) == 1

        return success
            ? .success(Data(tagBytes))
            : .failure(.encryptFailed(CryptoFailureMessages.getTagFailed))
    }

    static func decryptPayload(
        ctx: UnsafeMutablePointer<EVP_CIPHER_CTX>,
        ciphertext: Data
    ) -> Result<(Data, Int32), OpaqueFailure> {
        var plaintext = Data(count: ciphertext.count + OpaqueConstants.aesGcmTagLengthBytes)
        var totalLen: Int32 = 0

        let ok = ciphertext.withUnsafeBytes { cipherPtr in
            plaintext.withUnsafeMutableBytes { plainPtr in
                EVP_DecryptUpdate(
                    ctx,
                    plainPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    &totalLen,
                    cipherPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    Int32(ciphertext.count)
                ) == 1
            }
        }

        guard ok else {
            return .failure(.decryptFailed(CryptoFailureMessages.decryptUpdateFailed))
        }

        return .success((plaintext, totalLen))
    }

    static func setDecryptionTag(
        ctx: UnsafeMutablePointer<EVP_CIPHER_CTX>,
        tag: Data
    ) -> Result<Unit, OpaqueFailure> {
        guard tag.withUnsafeBytes({
            EVP_CIPHER_CTX_ctrl(
                ctx,
                EVP_CTRL_GCM_SET_TAG,
                Int32(tag.count),
                UnsafeMutableRawPointer(mutating: $0.baseAddress)
            ) == 1
        }) else {
            return .failure(.decryptFailed(CryptoFailureMessages.setTagFailed))
        }

        return .success(.value)
    }

    static func finalizeDecryption(
        ctx: UnsafeMutablePointer<EVP_CIPHER_CTX>,
        plaintext: inout Data,
        totalLen: Int32
    ) -> Result<Data, OpaqueFailure> {
        var finalLen: Int32 = 0
        
        let ok = plaintext.withUnsafeMutableBytes { plainPtr in
            EVP_DecryptFinal_ex(
                ctx,
                plainPtr.baseAddress?.assumingMemoryBound(to: UInt8.self).advanced(by: Int(totalLen)),
                &finalLen
            ) == 1
        }
        
        guard ok else {
            return .failure(.decryptFailed(CryptoFailureMessages.decryptFinalFailed))
        }
        
        return .success(plaintext.prefix(Int(totalLen + finalLen)))
    }
    
    static func initGCM(
        ctx: UnsafeMutablePointer<EVP_CIPHER_CTX>,
        key: Data,
        nonce: Data,
        operation: CipherOperation
    ) -> Result<Unit, OpaqueFailure> {
        let initFunc = operation == .encrypt ? EVP_EncryptInit_ex : EVP_DecryptInit_ex
        let cipherType = EVP_aes_256_gcm()

        guard initFunc(ctx, cipherType, nil, nil, nil) == 1 else {
            return operation == .encrypt
                ? .failure(.encryptFailed(CryptoFailureMessages.encryptInitAlgorithm))
                : .failure(.decryptFailed(CryptoFailureMessages.decryptInitAlgorithm))
        }

        return self.setIvLength(ctx: ctx, length: nonce.count, operation: operation)
            .flatMap { _ in
                self.initCtxWithKeyNonce(ctx: ctx, key: key, nonce: nonce, operation: operation)
            }
    }
    
    private static func initCtxWithKeyNonce(
        ctx: UnsafeMutablePointer<EVP_CIPHER_CTX>,
        key: Data,
        nonce: Data,
        operation: CipherOperation
    ) -> Result<Unit, OpaqueFailure> {
        let initFunc = operation == .encrypt ? EVP_EncryptInit_ex : EVP_DecryptInit_ex

        let result = key.withUnsafeBytes { keyPtr in
            nonce.withUnsafeBytes { noncePtr in
                initFunc(
                    ctx, nil, nil,
                    keyPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    noncePtr.baseAddress?.assumingMemoryBound(to: UInt8.self)
                )
            }
        }

        return (result != 0)
            ? .success(.value)
            : operation == .encrypt
                ? .failure(.encryptFailed(CryptoFailureMessages.encryptInitKeyNonce))
                : .failure(.decryptFailed(CryptoFailureMessages.decryptInitKeyNonce))
    }

    
    private static func setIvLength(
        ctx: UnsafeMutablePointer<EVP_CIPHER_CTX>,
        length: Int,
        operation: CipherOperation
    ) -> Result<Unit, OpaqueFailure> {
        let result = EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, Int32(length), nil)
        return result == 1
            ? .success(.value)
            : operation == .encrypt
                ? .failure(.encryptFailed(CryptoFailureMessages.setIvLength))
                : .failure(.decryptFailed(CryptoFailureMessages.setIvLength))
    }
    
    static func processAAD(
        ctx: UnsafeMutablePointer<EVP_CIPHER_CTX>,
        aad: Data,
        operation: CipherOperation
    ) -> Result<Unit, OpaqueFailure> {
        guard !aad.isEmpty else {
            return .success(.value)
        }

        let updateFunc = operation == .encrypt ? EVP_EncryptUpdate : EVP_DecryptUpdate
        
        let success = aad.withUnsafeBytes { aadPtr in
            var outLen: Int32 = 0
            return updateFunc(
                ctx,
                nil,
                &outLen,
                aadPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                Int32(aad.count)
            ) == 1
        }

        return success
            ? .success(.value)
            : operation == .encrypt
                ? .failure(.encryptFailed(CryptoFailureMessages.aadFailed))
                : .failure(.decryptFailed(CryptoFailureMessages.aadDecryptFailed))
    }
    
    @discardableResult
    static func withCipherCtx<ResultType>(
        operation: CipherOperation,
        _ body: (UnsafeMutablePointer<EVP_CIPHER_CTX>) -> Result<ResultType, OpaqueFailure>
    ) -> Result<ResultType, OpaqueFailure> {
        
        guard let ctx = EVP_CIPHER_CTX_new() else {
            return operation == .encrypt
                ? .failure(.encryptFailed(CryptoFailureMessages.failedToCreateContext))
                : .failure(.decryptFailed(CryptoFailureMessages.failedToCreateContext))
        }
        defer { EVP_CIPHER_CTX_free(ctx) }
        return body(ctx)
    }
}
