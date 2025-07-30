//
//  EVPCryptoUtils.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.07.2025.
//

import Foundation
import CryptoKit
import Security
import OpenSSL

enum EVPCryptoUtils {
    @discardableResult
    static func withEvpCtx<ResultType>(
        _ body: (OpaquePointer) -> Result<ResultType, OpaqueFailure>
    ) -> Result<ResultType, OpaqueFailure> {
        guard let ctx = EVP_MD_CTX_new() else {
            return .failure(.digestComputationFailed("Failed to create EVP_MD_CTX"))
        }
        defer { EVP_MD_CTX_free(ctx) }
        return body(ctx)
    }
    
    static func hkdfExtract(ikm: Data, salt: Data?) -> Result<Data, OpaqueFailure> {
        guard !ikm.isEmpty else {
            return .failure(.invalidInput("IKM is empty"))
        }

        let effectiveSalt = (salt?.isEmpty ?? true)
            ? Data(repeating: 0, count: SHA256.Digest.byteCount)
            : salt!

        let prk = HMAC<SHA256>.authenticationCode(for: ikm, using: SymmetricKey(data: effectiveSalt))
        return .success(Data(prk))
    }
    
    static func hkdfExpand(prk: Data, info: Data, outputLength: Int) -> Result<Data, OpaqueFailure> {
        guard !prk.isEmpty else {
            return .failure(.invalidInput("PRK is empty"))
        }
        
        let pseudoRandomKey = SymmetricKey(data: prk)
        let okm = HKDF<SHA256>.expand(
            pseudoRandomKey: pseudoRandomKey,
            info: info,
            outputByteCount: outputLength
        )
        
        let keyData = okm.withUnsafeBytes { Data($0) }
        return .success(keyData)
    }
    
    static func deriveKey(ikm: Data, salt: Data?, info: Data, outputLength: Int) -> Result<Data, OpaqueFailure> {
        guard !ikm.isEmpty else {
            return .failure(.invalidInput("IKM is empty"))
        }
        
        let pseudoRandomKey = SymmetricKey(data: ikm)
        let derived = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: pseudoRandomKey,
            salt: salt ?? Data(),
            info: info,
            outputByteCount: outputLength
        )
        
        let keyData = derived.withUnsafeBytes { Data($0) }
        return .success(keyData)
    }
    
    static func createMac(key: Data, data: Data) -> Result<Data, OpaqueFailure> {
        guard key.count == OpaqueConstants.macKeyLength else {
            return .failure(.invalidInput("HMAC key must be 32 bytes"))
        }
        
        let symmetricKey = SymmetricKey(data: key)
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)

        return .success(Data(hmac))
    }
    
    static func evpHash(
        ctx: OpaquePointer,
        inputs: [Data]
    ) -> Result<Data, OpaqueFailure> {
        guard EVP_DigestInit_ex(ctx, EVP_sha256(), nil) == 1 else {
            return .failure(.hashToPointFailed("Failed to initialize digest"))
        }

        for input in inputs {
            let result = input.withUnsafeBytes {
                EVP_DigestUpdate(ctx, $0.baseAddress, input.count) == 1
            }

            if !result {
                return .failure(.hashToPointFailed("Failed to update digest"))
            }
        }

        var hash = Data(repeating: 0, count: OpaqueConstants.defaultKeyLength)
        var outLen: UInt32 = 0
        let success = hash.withUnsafeMutableBytes {
            EVP_DigestFinal_ex(ctx, $0.baseAddress?.assumingMemoryBound(to: UInt8.self), &outLen) == 1
        }

        return success
            ? .success(hash)
            : .failure(.hashToPointFailed("Failed to finalize digest"))
    }
}
