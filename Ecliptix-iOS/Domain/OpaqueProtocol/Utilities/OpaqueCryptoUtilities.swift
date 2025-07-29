//
//  OpaqueCryptoUtilities.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 26.06.2025.
//

import Foundation
import CryptoKit
import Security
import OpenSSL

struct OpaqueCryptoUtilities {
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
        let symmetricKey = SymmetricKey(data: key)
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)

        return .success(Data(hmac))
    }
    
    static func recoverOprfKey(oprfResponse: Data, blind: UnsafePointer<BIGNUM>, group: OpaquePointer) -> Result<Data, OpaqueFailure> {
        guard let ctx = BN_CTX_new() else {
            return .failure(.invalidInput("Failed to allocate BN_CTX"))
        }
        defer { BN_CTX_free(ctx) }

        return ECPointUtils.decodeCompressedPoint(oprfResponse, group: group, ctx: ctx)
            .flatMap { point in
                defer { EC_POINT_free(point) }

                return ECPointUtils.getOrder(of: group, ctx: ctx)
                    .flatMap { order in
                        defer { BN_free(order) }

                        guard let blindInv = BN_mod_inverse(nil, blind, order, ctx) else {
                            return .failure(.invalidInput("Failed to compute modular inverse"))
                        }
                        defer { BN_free(blindInv) }

                        guard let finalPoint = EC_POINT_new(group),
                              EC_POINT_mul(group, finalPoint, nil, point, blindInv, ctx) == 1 else {
                            return .failure(.pointMultiplicationFailed("Failed to multiply point with inverse"))
                        }
                        defer { EC_POINT_free(finalPoint) }

                        return ECPointUtils.compressPoint(finalPoint, group: group, ctx: ctx)
                    }
            }
    }

    static func hashToPoint(_ input: Data) -> Result<Data, OpaqueFailure> {
        guard let ctx = EVP_MD_CTX_new() else {
            return .failure(.hashingValidPointFailed("Failed to create EVP context"))
        }
        defer { EVP_MD_CTX_free(ctx) }

        guard let ecGroup = EC_GROUP_new_by_curve_name(NID_X9_62_prime256v1) else {
            return .failure(.hashingValidPointFailed("Failed to create curve group"))
        }
        defer { EC_GROUP_free(ecGroup) }

        guard let bnCtx = BN_CTX_new() else {
            return .failure(.hashingValidPointFailed("Failed to create BN_CTX"))
        }
        defer { BN_CTX_free(bnCtx) }

        let hashLen = Int(EVP_MD_get_size(EVP_sha256()))
        var counter: UInt8 = 0

        while counter < 255 {
            var hash = [UInt8](repeating: 0, count: hashLen)

            EVP_DigestInit_ex(ctx, EVP_sha256(), nil)
            input.withUnsafeBytes { _ = EVP_DigestUpdate(ctx, $0.baseAddress, input.count) }
            withUnsafeBytes(of: counter) { _ = EVP_DigestUpdate(ctx, $0.baseAddress, 1) }
            EVP_DigestFinal_ex(ctx, &hash, nil)

            let pubKeyBytes = [OpaqueConstants.ecCompressedPrefixEven] + hash.prefix(OpaqueConstants.defaultKeyLength)
            let compressed = Data(pubKeyBytes)
            
            let decodeResult = ECPointUtils.decodeCompressedPoint(compressed, group: ecGroup, ctx: bnCtx)
            if case let .success(point) = decodeResult {
                defer { EC_POINT_free(point) }

                if EC_POINT_is_on_curve(ecGroup, point, bnCtx) == 1 {
                    return ECPointUtils.compressPoint(point, group: ecGroup, ctx: bnCtx)
                }
            }

            counter += 1
        }

        return .failure(.hashingValidPointFailed("Failed to find valid EC point in 255 attempts"))
    }
}

extension Data {
    init(hex: String) {
        self.init()
        var hexStr = hex
        if hexStr.count % 2 != 0 {
            hexStr = "0" + hexStr
        }

        var index = hexStr.startIndex
        while index < hexStr.endIndex {
            let nextIndex = hexStr.index(index, offsetBy: 2)
            if nextIndex <= hexStr.endIndex {
                let byteString = hexStr[index..<nextIndex]
                if let num = UInt8(byteString, radix: 16) {
                    self.append(num)
                }
            }
            index = nextIndex
        }
    }
}
