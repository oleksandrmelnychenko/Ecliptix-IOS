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

class OpaqueCryptoUtilities {
    
    static func hkdfExtract(ikm: Data, salt: Data?) -> Result<Data, OpaqueFailure> {
        guard !ikm.isEmpty else {
            return .failure(.invalidInput())
        }

        let effectiveSalt = (salt?.isEmpty ?? true)
            ? Data(repeating: 0, count: SHA256.Digest.byteCount)
            : salt!

        do {
            let prk = HMAC<SHA256>.authenticationCode(for: ikm, using: SymmetricKey(data: effectiveSalt))
            return .success(Data(prk))
        } catch {
            return .failure(.invalidKeySignature(error.localizedDescription, inner: error))
        }
    }
    
    static func hkdfExpand(prk: Data, info: Data, outputLength: Int) -> Data {
        let pseudoRandomKey = SymmetricKey(data: prk)
        let okm = HKDF<SHA256>.expand(
            pseudoRandomKey: pseudoRandomKey,
            info: info,
            outputByteCount: outputLength
        )
        return okm.withUnsafeBytes { Data($0) }
    }
    
    static func deriveKey(ikm: Data, salt: Data?, info: Data, outputLength: Int) -> Data {
        let pseudoRandomKey = SymmetricKey(data: ikm)
        
        let derived = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: pseudoRandomKey,
            salt: salt ?? Data(),
            info: info,
            outputByteCount: outputLength
        )
        
        return derived.withUnsafeBytes { Data($0) }
    }
    
    static func generateRandomScalar(group: OpaquePointer) -> UnsafeMutablePointer<BIGNUM>? {
        let group = group
        let ctx = BN_CTX_new()
        guard ctx != nil else { return nil }
        defer { BN_CTX_free(ctx) }

        // Отримуємо порядок групи (N)
        let order = BN_new()
        guard order != nil else { return nil }
        defer { BN_free(order) }

        guard EC_GROUP_get_order(group, order, ctx) == 1 else { return nil }

        // Генеруємо випадкове число в діапазоні [1, order-1]
        let scalar = BN_new()
        guard scalar != nil else { return nil }

        repeat {
            // BN_rand_range генерує [0, order)
            if BN_rand_range(scalar, order) != 1 {
                BN_free(scalar)
                return nil
            }
        } while BN_is_zero(scalar) == 1

        return scalar
    }
    
    public static func generateKeyPair(group: OpaquePointer) -> (privateKey: UnsafeMutablePointer<BIGNUM>, publicKey: OpaquePointer)? {
        let group = group
        let ctx = BN_CTX_new()
        guard ctx != nil else { return nil }
        defer { BN_CTX_free(ctx) }

        // Отримати порядок групи
        let order = BN_new()
        guard order != nil else { return nil }
        defer { BN_free(order) }

        guard EC_GROUP_get_order(group, order, ctx) == 1 else { return nil }

        // Згенерувати приватний ключ: випадкове число в межах [1, order - 1]
        let privateKey = BN_new()
        guard privateKey != nil else { return nil }

        repeat {
            if BN_rand_range(privateKey, order) != 1 {
                BN_free(privateKey)
                return nil
            }
        } while BN_is_zero(privateKey) == 1

        // Обчислити публічний ключ: pubKey = G * privKey
        guard let publicKey = EC_POINT_new(group) else {
            BN_free(privateKey)
            return nil
        }

        guard EC_POINT_mul(group, publicKey, privateKey, nil, nil, ctx) == 1 else {
            EC_POINT_free(publicKey)
            BN_free(privateKey)
            return nil
        }

        return (privateKey: privateKey!, publicKey: publicKey)
    }

    static func hashToPoint(_ input: Data) -> Result<Data, OpaqueFailure> {
        let ctx = EVP_MD_CTX_new()
        guard ctx != nil else {
            return .failure(.hashingValidPointFailed("Failed to create EVP context"))
        }
        defer { EVP_MD_CTX_free(ctx) }

        var counter: UInt8 = 0
        let maxAttempts: UInt8 = 255

        while counter < maxAttempts {
            // 1. Hash input + counter
            var hash = Data(repeating: 0, count: Int(EVP_MD_get_size(EVP_sha256())))
            EVP_DigestInit_ex(ctx, EVP_sha256(), nil)
            _ = input.withUnsafeBytes { EVP_DigestUpdate(ctx, $0.baseAddress, input.count) }
            var c = counter
            _ = withUnsafeBytes(of: &c) { EVP_DigestUpdate(ctx, $0.baseAddress, 1) }
            _ = hash.withUnsafeMutableBytes {
                EVP_DigestFinal_ex(ctx, $0.baseAddress?.assumingMemoryBound(to: UInt8.self), nil)
            }

            // 2. Convert hash to BIGNUM x
            guard let x = BN_bin2bn([UInt8](hash), Int32(hash.count), nil),
                  let max = BN_new() else {
                counter += 1
                continue
            }
            defer {
                BN_free(x)
                BN_free(max)
            }

            let maxBytes = [UInt8](repeating: 0xFF, count: 32)
            _ = BN_bin2bn(maxBytes, 32, max)

            if BN_is_zero(x) == 0 && BN_cmp(x, max) < 0 {
                // 3. Try to interpret hash as compressed EC point
                let pub = Data([0x02]) + hash.prefix(32)
                let ecGroup = EC_GROUP_new_by_curve_name(NID_X9_62_prime256v1)!
                defer { EC_GROUP_free(ecGroup) }

                let bnCtx = BN_CTX_new()!
                defer { BN_CTX_free(bnCtx) }

                guard let point = EC_POINT_new(ecGroup) else {
                    counter += 1
                    continue
                }
                defer { EC_POINT_free(point) }

                let buf = pub.withUnsafeBytes { $0.baseAddress?.assumingMemoryBound(to: UInt8.self) }
                if EC_POINT_oct2point(ecGroup, point, buf, pub.count, bnCtx) != 1 ||
                    EC_POINT_is_on_curve(ecGroup, point, bnCtx) != 1 {
                    counter += 1
                    continue
                }

                // 4. Return compressed point
                var compressed = Data(repeating: 0, count: 33)
                let written = compressed.withUnsafeMutableBytes {
                    EC_POINT_point2oct(ecGroup, point, POINT_CONVERSION_COMPRESSED,
                                       $0.baseAddress?.assumingMemoryBound(to: UInt8.self),
                                       33, bnCtx)
                }

                if written == 33 {
                    return .success(compressed)
                }
            }

            counter += 1
        }

        return .failure(.hashingValidPointFailed("Failed to find valid EC point in \(maxAttempts) attempts"))
    }


    
    static func encrypt(plaintext: Data, key: Data, associatedData: Data?) -> Result<Data, OpaqueFailure> {
        guard key.count == OpaqueConstants.defaultKeyLength else {
            return .failure(.encryptFailed("Invalid key length"))
        }

        let ctx = EVP_CIPHER_CTX_new()
        defer { EVP_CIPHER_CTX_free(ctx) }

        var outLen: Int32 = 0
        var tag = Data(count: 16)
        var ciphertext = Data(count: plaintext.count + 16) // + block size just in case

        // Nonce
        let nonce = (0..<OpaqueConstants.aesGcmNonceLengthBytes).map { _ in UInt8.random(in: 0...255) }
        let nonceData = Data(nonce)

        // Init encryption
        guard EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), nil, nil, nil) == 1 else {
            return .failure(.encryptFailed("Init failed"))
        }

        guard EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, Int32(nonceData.count), nil) == 1 else {
            return .failure(.encryptFailed("Setting IV length failed"))
        }

        // Set key and IV
        key.withUnsafeBytes { keyPtr in
            _ = nonceData.withUnsafeBytes { noncePtr in
                EVP_EncryptInit_ex(ctx, nil, nil, keyPtr.baseAddress?.assumingMemoryBound(to: UInt8.self), noncePtr.baseAddress?.assumingMemoryBound(to: UInt8.self))
            }
        }

        // AAD
        if let aad = associatedData, !aad.isEmpty {
            _ = aad.withUnsafeBytes { aadPtr in
                EVP_EncryptUpdate(ctx, nil, &outLen, aadPtr.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(aad.count))
            }
        }

        // Encrypt
        var cipherLen: Int32 = 0
        plaintext.withUnsafeBytes { plainPtr in
            _ = ciphertext.withUnsafeMutableBytes { cipherPtr in
                EVP_EncryptUpdate(ctx, cipherPtr.baseAddress?.assumingMemoryBound(to: UInt8.self), &cipherLen, plainPtr.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(plaintext.count))
            }
        }

        outLen = 0
        _ = ciphertext.withUnsafeMutableBytes {
            EVP_EncryptFinal_ex(ctx, $0.baseAddress?.assumingMemoryBound(to: UInt8.self).advanced(by: Int(cipherLen)), &outLen)
        }

        // Get Tag
        _ = tag.withUnsafeMutableBytes {
            EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, 16, $0.baseAddress)
        }

        // Combine nonce + ciphertext + tag
        var output = Data()
        output.append(nonceData)
        output.append(ciphertext.prefix(Int(cipherLen)))
        output.append(tag)

        return .success(output)
    }


    static func decrypt(ciphertextWithNonce: Data, key: Data, associatedData: Data?) -> Result<Data, OpaqueFailure> {
        guard key.count == OpaqueConstants.defaultKeyLength else {
            return .failure(.decryptFailed("Invalid key length"))
        }

        let nonceLen = OpaqueConstants.aesGcmNonceLengthBytes
        let tagLen = OpaqueConstants.aesGcmTagLengthBits / 8

        guard ciphertextWithNonce.count >= nonceLen + tagLen else {
            return .failure(.decryptFailed("Ciphertext too short"))
        }

        let nonce = ciphertextWithNonce.prefix(nonceLen)
        let tag = ciphertextWithNonce.suffix(tagLen)
        let ciphertext = ciphertextWithNonce.dropFirst(nonceLen).dropLast(tagLen)

        let ctx = EVP_CIPHER_CTX_new()
        defer { EVP_CIPHER_CTX_free(ctx) }

        guard EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), nil, nil, nil) == 1 else {
            return .failure(.decryptFailed("Init failed"))
        }

        guard EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, Int32(nonce.count), nil) == 1 else {
            return .failure(.decryptFailed("Setting IV length failed"))
        }

        key.withUnsafeBytes { keyPtr in
            _ = nonce.withUnsafeBytes { noncePtr in
                EVP_DecryptInit_ex(ctx, nil, nil, keyPtr.baseAddress?.assumingMemoryBound(to: UInt8.self), noncePtr.baseAddress?.assumingMemoryBound(to: UInt8.self))
            }
        }

        if let aad = associatedData, !aad.isEmpty {
            aad.withUnsafeBytes { aadPtr in
                var outLen: Int32 = 0
                EVP_DecryptUpdate(ctx, nil, &outLen, aadPtr.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(aad.count))
            }
        }

        var plaintext = Data(count: ciphertext.count)
        var outLen: Int32 = 0
        ciphertext.withUnsafeBytes { cipherPtr in
            _ = plaintext.withUnsafeMutableBytes { plainPtr in
                EVP_DecryptUpdate(ctx, plainPtr.baseAddress?.assumingMemoryBound(to: UInt8.self), &outLen, cipherPtr.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(ciphertext.count))
            }
        }

        // Set tag
        _ = tag.withUnsafeBytes {
            EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, Int32(tag.count), UnsafeMutableRawPointer(mutating: $0.baseAddress))
        }

        if EVP_DecryptFinal_ex(ctx, nil, &outLen) != 1 {
            return .failure(.decryptFailed("Invalid tag, authentication failed"))
        }

        return .success(plaintext.prefix(Int(outLen)))
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
