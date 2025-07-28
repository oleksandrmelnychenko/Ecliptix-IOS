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
    
    static func encrypt(plaintext: Data, key: Data, associatedData: Data?) -> Result<Data, OpaqueFailure> {
        guard key.count == OpaqueConstants.defaultKeyLength else {
            return .failure(.encryptFailed("Invalid key length"))
        }

        guard let ctx = EVP_CIPHER_CTX_new() else {
            return .failure(.encryptFailed("Failed to create cipher context"))
        }
        defer { EVP_CIPHER_CTX_free(ctx) }
        
        let nonce = Data((0..<OpaqueConstants.aesGcmNonceLengthBytes).map { _ in UInt8.random(in: 0...255) })

        // Init context
        guard EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), nil, nil, nil) == 1 else {
            return .failure(.encryptFailed("EncryptInit_ex failed"))
        }

        guard EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, Int32(nonce.count), nil) == 1 else {
            return .failure(.encryptFailed("Setting IV length failed"))
        }

        guard key.withUnsafeBytes({ keyPtr in
            nonce.withUnsafeBytes { noncePtr in
                EVP_EncryptInit_ex(
                    ctx, nil, nil,
                    keyPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    noncePtr.baseAddress?.assumingMemoryBound(to: UInt8.self)
                ) == 1
            }
        }) else {
            return .failure(.encryptFailed("EncryptInit_ex key/nonce failed"))
        }

        // AAD
        if let aad = associatedData, !aad.isEmpty {
            let result = aad.withUnsafeBytes { aadPtr in
                var outLen: Int32 = 0
                return EVP_EncryptUpdate(
                    ctx,
                    nil,
                    &outLen,
                    aadPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    Int32(aad.count)
                ) == 1
            }
            if !result {
                return .failure(.encryptFailed("AAD failed"))
            }
        }

        // Ciphertext
        var ciphertext = Data(count: plaintext.count)
        var cipherLen: Int32 = 0
        
        let updateOk = plaintext.withUnsafeBytes { plainPtr in
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

        if !updateOk {
            return .failure(.encryptFailed("EncryptUpdate failed"))
        }
        
        // Finalize
        var finalLen: Int32 = 0
        guard ciphertext.withUnsafeMutableBytes({
            EVP_EncryptFinal_ex(
                ctx,
                $0.baseAddress?.assumingMemoryBound(to: UInt8.self).advanced(by: Int(cipherLen)),
                &finalLen
            ) == 1
        }) else {
            return .failure(.encryptFailed("EncryptFinal failed"))
        }

        // Get tag
        var tagBytes = [UInt8](repeating: 0, count: OpaqueConstants.aesGcmTagLengthBytes)
        guard EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, Int32(tagBytes.count), &tagBytes) == 1 else {
            return .failure(.encryptFailed("Get TAG failed"))
        }
        let tag = Data(tagBytes)

        // Compose output
        var output = Data()
        output.append(nonce)
        output.append(ciphertext.prefix(Int(cipherLen)))
        output.append(tag)

        return .success(output)
    }
    
    static func decrypt(ciphertextWithNonce: Data, key: Data, associatedData: Data?) -> Result<Data, OpaqueFailure> {
        guard key.count == OpaqueConstants.defaultKeyLength else {
            return .failure(.decryptFailed("Invalid key length"))
        }

        let nonceLen = OpaqueConstants.aesGcmNonceLengthBytes
        let tagLen = OpaqueConstants.aesGcmTagLengthBytes

        guard ciphertextWithNonce.count >= nonceLen + tagLen else {
            return .failure(.decryptFailed("Ciphertext too short"))
        }

        let nonce = ciphertextWithNonce.prefix(nonceLen)
        let tag = ciphertextWithNonce.suffix(tagLen)
        let ciphertext = ciphertextWithNonce.dropFirst(nonceLen).dropLast(tagLen)

        guard let ctx = EVP_CIPHER_CTX_new() else {
            return .failure(.decryptFailed("Failed to create cipher context"))
        }
        defer { EVP_CIPHER_CTX_free(ctx) }

        guard EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), nil, nil, nil) == 1 else {
            return .failure(.decryptFailed("DecryptInit failed"))
        }

        guard EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, Int32(nonce.count), nil) == 1 else {
            return .failure(.decryptFailed("Setting IV length failed"))
        }

        guard key.withUnsafeBytes({ keyPtr in
            nonce.withUnsafeBytes { noncePtr in
                EVP_DecryptInit_ex(
                    ctx, nil, nil,
                    keyPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    noncePtr.baseAddress?.assumingMemoryBound(to: UInt8.self)
                ) == 1
            }
        }) else {
            return .failure(.decryptFailed("DecryptInit_ex key/nonce failed"))
        }

        if let aad = associatedData, !aad.isEmpty {
            let aadOk = aad.withUnsafeBytes { aadPtr in
                var outLen: Int32 = 0
                return EVP_DecryptUpdate(ctx, nil, &outLen,
                                         aadPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                                         Int32(aad.count)) == 1
            }
            if !aadOk {
                return .failure(.decryptFailed("AAD failed"))
            }
        }

        var plaintext = Data(count: ciphertext.count + tagLen)
        var totalLen: Int32 = 0

        let updateOk = ciphertext.withUnsafeBytes { cipherPtr in
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

        if !updateOk {
            return .failure(.decryptFailed("DecryptUpdate failed"))
        }

        // Set TAG
        guard tag.withUnsafeBytes({
            EVP_CIPHER_CTX_ctrl(
                ctx,
                EVP_CTRL_GCM_SET_TAG,
                Int32(tag.count),
                UnsafeMutableRawPointer(mutating: $0.baseAddress)
            ) == 1
        }) else {
            return .failure(.decryptFailed("Setting tag failed"))
        }

        // Finalize decryption
        var finalLen: Int32 = 0
        let finalOk = plaintext.withUnsafeMutableBytes { plainPtr in
            EVP_DecryptFinal_ex(
                ctx,
                plainPtr.baseAddress?.assumingMemoryBound(to: UInt8.self).advanced(by: Int(totalLen)),
                &finalLen
            ) == 1
        }
        
        if !finalOk {
            return .failure(.decryptFailed("Invalid tag, authentication failed"))
        }

        return .success(plaintext.prefix(Int(totalLen + finalLen)))
    }
    
    static func createMac(key: Data, data: Data) -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)
        return Data(hmac)
    }
    
    static func recoverOprfKey(oprfResponse: Data, blind: UnsafePointer<BIGNUM>, group: OpaquePointer) -> Result<Data, OpaqueFailure> {
        let ctx = BN_CTX_new()!
        defer { BN_CTX_free(ctx) }

        guard let point = EC_POINT_new(group) else {
            return .failure(.pointDecodingFailed("Failed to create EC_POINT"))
        }
        defer { EC_POINT_free(point) }

        guard EC_POINT_oct2point(group, point, [UInt8](oprfResponse), oprfResponse.count, ctx) == 1 else {
            return .failure(.pointDecodingFailed("Failed to decode EC_POINT"))
        }

        guard let order = BN_new(), EC_GROUP_get_order(group, order, ctx) == 1 else {
            return .failure(.invalidInput("Failed to get group order"))
        }
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

            guard let x = BN_bin2bn(hash, Int32(hash.count), nil) else {
                counter += 1
                continue
            }
            defer { BN_free(x) }

            // Якщо x валідне — створити EC_POINT
            let pubKeyBytes = [OpaqueConstants.ecCompressedPrefixEven] + hash.prefix(OpaqueConstants.defaultKeyLength)
            guard let point = EC_POINT_new(ecGroup) else {
                counter += 1
                continue
            }
            defer { EC_POINT_free(point) }

            let success = pubKeyBytes.withUnsafeBytes {
                EC_POINT_oct2point(ecGroup, point, $0.baseAddress?.assumingMemoryBound(to: UInt8.self), pubKeyBytes.count, bnCtx) == 1 &&
                EC_POINT_is_on_curve(ecGroup, point, bnCtx) == 1
            }

            if success {
                return ECPointUtils.compressPoint(point, group: ecGroup, ctx: bnCtx)
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
