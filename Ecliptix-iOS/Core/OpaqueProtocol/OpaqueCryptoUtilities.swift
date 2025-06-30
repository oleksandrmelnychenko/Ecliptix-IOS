//
//  OpaqueCryptoUtilities.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 26.06.2025.
//

import Foundation
import CryptoKit
import BigInt
import Security
import OpenSSL

enum ECCurve {
    // Параметр N для secp256r1 (P-256) — порядок базової точки
    static let domainN = BigUInt("ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551", radix: 16)!
}

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
        let ctx = EVP_MD_CTX_new()!
        defer { EVP_MD_CTX_free(ctx) }

        var counter: UInt8 = 0
        let maxAttempts: UInt8 = 255

        while counter < maxAttempts {
            var hash = Data(repeating: 0, count: Int(EVP_MD_get_size(EVP_sha256())))
            EVP_DigestInit_ex(ctx, EVP_sha256(), nil)
            _ = input.withUnsafeBytes { EVP_DigestUpdate(ctx, $0.baseAddress, input.count) }
            var c = counter
            _ = withUnsafeBytes(of: &c) { EVP_DigestUpdate(ctx, $0.baseAddress, 1) }
            _ = hash.withUnsafeMutableBytes {
                EVP_DigestFinal_ex(ctx, $0.baseAddress?.assumingMemoryBound(to: UInt8.self), nil)
            }

            let x = BigUInt(hash)
            let max = BigUInt(Data(repeating: 0xFF, count: 32))

            if x > 0 && x < max {
                let pub = Data([0x02]) + hash.prefix(32)
                let ecGroup = EC_GROUP_new_by_curve_name(NID_X9_62_prime256v1)!
                let bnCtx = BN_CTX_new()!
                defer {
                    EC_GROUP_free(ecGroup)
                    BN_CTX_free(bnCtx)
                }

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

                var compressed = Data(repeating: 0, count: 33)
                let length = compressed.count

                var buffer = compressed
                let written = buffer.withUnsafeMutableBytes {
                    EC_POINT_point2oct(ecGroup, point, POINT_CONVERSION_COMPRESSED,
                                       $0.baseAddress?.assumingMemoryBound(to: UInt8.self),
                                       length, bnCtx)
                }

                if written > 0 {
                    compressed = buffer
                    return .success(compressed)
                }

            }

            counter += 1
        }

        return .failure(.hashingValidPointFailed())
    }

    
    static func encrypt(plaintext: Data, key: Data, associatedData: Data?) -> Result<Data, OpaqueFailure> {
        guard key.count == OpaqueConstants.defaultKeyLength else {
            return .failure(.encryptFailed("Invalid key length"))
        }

        let symmetricKey = SymmetricKey(data: key)
        let nonceBytes = (0..<OpaqueConstants.aesGcmNonceLengthBytes).map { _ in UInt8.random(in: 0...255) }
        let nonce = try! AES.GCM.Nonce(data: Data(nonceBytes))

        do {
            let sealedBox = try AES.GCM.seal(plaintext, using: symmetricKey, nonce: nonce, authenticating: associatedData ?? Data())
            var combined = Data()
            combined.append(contentsOf: nonceBytes)
            combined.append(sealedBox.ciphertext)
            combined.append(sealedBox.tag)
            return .success(combined)
        } catch {
            return .failure(.encryptFailed(error.localizedDescription))
        }
    }

    static func decrypt(ciphertextWithNonce: Data, key: Data, associatedData: Data?) -> Result<Data, OpaqueFailure> {
        guard key.count == OpaqueConstants.defaultKeyLength else {
            return .failure(.decryptFailed("Invalid key length"))
        }

        let totalOverhead = OpaqueConstants.aesGcmNonceLengthBytes + (OpaqueConstants.aesGcmTagLengthBits / 8)
        guard ciphertextWithNonce.count >= totalOverhead else {
            return .failure(.decryptFailed("Ciphertext too short"))
        }

        let symmetricKey = SymmetricKey(data: key)
        let nonce = try! AES.GCM.Nonce(data: ciphertextWithNonce.prefix(OpaqueConstants.aesGcmNonceLengthBytes))
        let tagStart = ciphertextWithNonce.count - (OpaqueConstants.aesGcmTagLengthBits / 8)
        let ciphertext = ciphertextWithNonce[OpaqueConstants.aesGcmNonceLengthBytes..<tagStart]
        let tag = ciphertextWithNonce.suffix(OpaqueConstants.aesGcmTagLengthBits / 8)

        do {
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
            let decrypted = try AES.GCM.open(sealedBox, using: symmetricKey, authenticating: associatedData ?? Data())
            return .success(decrypted)
        } catch {
            return .failure(.decryptFailed(error.localizedDescription))
        }
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
