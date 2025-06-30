//
//  OpaqueProtocolService.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 26.06.2025.
//

import Foundation
import CryptoKit
import OpenSSL


class OpaqueProtocolService {
    private let staticPublicKey: Data
    private let staticPublicKeyPoint: OpaquePointer?
    private let defaultGroup: OpaquePointer

    init(staticPublicKey: Data) {
        self.staticPublicKey = staticPublicKey

        let group = Self.getDefaultGroup()
        self.defaultGroup = group

        let staticPublicKeyPoint: OpaquePointer? = staticPublicKey.withUnsafeBytes {
            guard let point = EC_POINT_new(group) else { return nil }
            let result = EC_POINT_oct2point(
                group,
                point,
                $0.baseAddress?.assumingMemoryBound(to: UInt8.self),
                staticPublicKey.count,
                nil
            )
            return result == 1 ? point : nil
        }

        self.staticPublicKeyPoint = staticPublicKeyPoint
    }
    
    deinit {
        if let point = staticPublicKeyPoint {
            EC_POINT_free(point)
        }
    }
    
    private static var cachedGroup: OpaquePointer = {
        EC_GROUP_new_by_curve_name(NID_X9_62_prime256v1)!
    }()
    
    private static func getDefaultGroup() -> OpaquePointer {
        return cachedGroup
    }
    
    static func createOprfRequest(password: Data) -> Result<(oprfRequest: Data, blind: UnsafeMutablePointer<BIGNUM>), OpaqueFailure> {
        do {            
            guard let blind = OpaqueCryptoUtilities.generateRandomScalar(group: getDefaultGroup()) else {
                return .failure(.invalidInput("Failed to generate random scalar"))
            }
            
            let hashResult = OpaqueCryptoUtilities.hashToPoint(password)
            guard case let .success(pointEncoded) = hashResult else {
                return .failure(try hashResult.unwrapErr())
            }
            
            // Декодуємо точку з байтів (pointEncoded — стиснена точка)
            let group = getDefaultGroup()
            let ctx = BN_CTX_new()!
            defer { BN_CTX_free(ctx) }

            guard let point = EC_POINT_new(group) else {
                return .failure(.pointDecodingFailed("Failed to create EC_POINT"))
            }
            defer { EC_POINT_free(point) }

            let decodeSuccess = pointEncoded.withUnsafeBytes {
                EC_POINT_oct2point(group, point, $0.baseAddress!.assumingMemoryBound(to: UInt8.self), $0.count, ctx) == 1
            }
            guard decodeSuccess else {
                return .failure(.pointDecodingFailed("Failed to decode hashed point"))
            }
            
            // Обчислюємо final = point * blind
            guard let finalPoint = EC_POINT_new(group) else {
                return .failure(.pointMultiplicationFailed("Failed to allocate finalPoint"))
            }
            defer { EC_POINT_free(finalPoint) }

            guard EC_POINT_mul(group, finalPoint, nil, point, blind, ctx) == 1 else {
                return .failure(.pointMultiplicationFailed("Failed to multiply point with blind"))
            }

            // Стиснене представлення
            var compressed = Data(repeating: 0, count: 33)
            let written = compressed.withUnsafeMutableBytes {
                EC_POINT_point2oct(group, finalPoint, POINT_CONVERSION_COMPRESSED,
                                   $0.baseAddress?.assumingMemoryBound(to: UInt8.self),
                                   33, ctx)
            }

            guard written == 33 else {
                return .failure(.pointCompressionFailed("Compressed point size incorrect"))
            }

            return .success((oprfRequest: compressed, blind: blind))
        } catch {
            return .failure(.invalidInput("Error during create oprf request", inner: error))
        }
    }
    
    static func createRegistrationRecord(password: Data, oprfResponse: Data, blind: UnsafePointer<BIGNUM>) -> Result<Data, OpaqueFailure> {
        do {
            // 1. Recover OPRF key
            let oprfKeyResult = recoverOprfKey(oprfResponse: oprfResponse, blind: blind)
            guard case let .success(oprfKey) = oprfKeyResult else {
                return .failure(try oprfKeyResult.unwrapErr())
            }

            // 2. Derive credential key
            let credentialKey = OpaqueCryptoUtilities.deriveKey(
                ikm: oprfKey,
                salt: nil,
                info: OpaqueConstants.credentialKeyInfo,
                outputLength: OpaqueConstants.defaultKeyLength
            )

            // 3. Generate client static key pair (OpenSSL)
            guard let (privBN, pubPoint) = OpaqueCryptoUtilities.generateKeyPair(group: getDefaultGroup()) else {
                return .failure(.invalidInput("Failed to generate EC key pair"))
            }
            defer {
                BN_free(privBN)
                EC_POINT_free(pubPoint)
            }

            // Приватний ключ → Data
            let privLength = (BN_num_bits(privBN) + 7) / 8
            var privBytes = [UInt8](repeating: 0, count: Int(privLength))
            BN_bn2bin(privBN, &privBytes)
            let clientPrivateKeyBytes = Data(privBytes)

            // Публічний ключ → стиснене представлення (33 байти)
            var pubBytes = Data(repeating: 0, count: 33)
            let pubWritten = pubBytes.withUnsafeMutableBytes {
                EC_POINT_point2oct(getDefaultGroup(), pubPoint, POINT_CONVERSION_COMPRESSED,
                                   $0.baseAddress?.assumingMemoryBound(to: UInt8.self),
                                   33, nil)
            }

            guard pubWritten == 33 else {
                return .failure(.pointCompressionFailed("Invalid public key size"))
            }
            let clientPublicKeyBytes = pubBytes

            // 4. Encrypt private key using AEAD
            let envelopeResult = OpaqueCryptoUtilities.encrypt(
                plaintext: clientPrivateKeyBytes,
                key: credentialKey,
                associatedData: password
            )

            guard case let .success(envelope) = envelopeResult else {
                return .failure(try envelopeResult.unwrapErr())
            }

            // 5. Combine public key and envelope
            var registrationRecord = Data()
            registrationRecord.append(clientPublicKeyBytes)
            registrationRecord.append(envelope)

            return .success(registrationRecord)
        } catch {
            return .failure(.invalidInput("Error during create registration record", inner: error))
        }
    }

    
    // not sure
    public func createSignInFinalizationRequest(
        phoneNumber: String,
        passwordData: Data,
        signInResponse: Ecliptix_Proto_Membership_OpaqueSignInInitResponse,
        blind: UnsafePointer<BIGNUM>
    ) -> Result<(Ecliptix_Proto_Membership_OpaqueSignInFinalizeRequest, Data, Data, Data), OpaqueFailure> {
        do {
            // Відновлення OPRF ключа
            let oprfKeyRecoveryResult = Self.recoverOprfKey(oprfResponse: signInResponse.serverOprfResponse, blind: blind)
            guard oprfKeyRecoveryResult.isOk else {
                return .failure(.invalidInput("Invalid server OPRF response."))
            }
            let oprfKey = try oprfKeyRecoveryResult.unwrap()

            // Вивід credentialKey
            let credentialKey = OpaqueCryptoUtilities.deriveKey(
                ikm: oprfKey,
                salt: nil,
                info: OpaqueConstants.credentialKeyInfo,
                outputLength: OpaqueConstants.defaultKeyLength
            )

            guard signInResponse.registrationRecord.count >= OpaqueConstants.compressedPublicKeyLength else {
                return .failure(.invalidInput("Invalid registration record: too short."))
            }

            let clientStaticPublicKeyBytes = signInResponse.registrationRecord.prefix(OpaqueConstants.compressedPublicKeyLength)
            let envelope = signInResponse.registrationRecord.dropFirst(OpaqueConstants.compressedPublicKeyLength)

            let decryptedResult = OpaqueCryptoUtilities.decrypt(ciphertextWithNonce: envelope, key: credentialKey, associatedData: passwordData)
            guard decryptedResult.isOk else {
                return .failure(try decryptedResult.unwrapErr())
            }
            let clientStaticPrivateKeyData = try decryptedResult.unwrap()

            guard let clientStaticPrivateKeyBN = BN_bin2bn([UInt8](clientStaticPrivateKeyData), Int32(clientStaticPrivateKeyData.count), nil) else {
                return .failure(.invalidInput("Failed to create private key BIGNUM"))
            }

            guard let (ephPrivateBN, ephPublicPoint) = OpaqueCryptoUtilities.generateKeyPair(group: Self.getDefaultGroup()) else {
                return .failure(.invalidInput("Failed to generate ephemeral key pair"))
            }
            
            defer {
                BN_free(ephPrivateBN)
                EC_POINT_free(ephPublicPoint)
            }
            
            guard
                let statSPubPoint = staticPublicKeyPoint,
                let ephSPubPoint = decodeCompressedPoint(signInResponse.serverEphemeralPublicKey, group: defaultGroup)
            else {
                return .failure(.invalidInput("Failed to convert keys to EC_POINT or BIGNUM"))
            }

            let akeResult = Self.performClientAke(
                ephPrivateKey: ephPrivateBN,
                statPrivateKey: clientStaticPrivateKeyBN,
                statSPub: statSPubPoint,
                ephSPub: ephSPubPoint
            )
            guard akeResult.isOk else {
                return .failure(.invalidInput("Failed to perform client AKE"))
            }
            let ake = try akeResult.unwrap()
            
            var clientEphemeralPubKey = Data(repeating: 0, count: 33)
            let written = clientEphemeralPubKey.withUnsafeMutableBytes {
                EC_POINT_point2oct(
                    defaultGroup,
                    ephPublicPoint,
                    POINT_CONVERSION_COMPRESSED,
                    $0.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    33,
                    nil
                )
            }

            guard written == 33 else {
                return .failure(.pointCompressionFailed("Invalid ephemeral public key size"))
            }
            let serverStaticPubKey = self.staticPublicKey  // уже доступний як Data

            let transcriptHash = hashTranscript(
                phoneNumber: phoneNumber,
                oprfResponse: signInResponse.serverOprfResponse,
                clientStaticPublicKey: clientStaticPublicKeyBytes,
                clientEphemeralPublicKey: clientEphemeralPubKey,
                serverStaticPublicKey: serverStaticPubKey,
                serverEphemeralPublicKey: signInResponse.serverEphemeralPublicKey
            )

            let keysResult = Self.deriveFinalKeys(akeResult: ake, transcriptHash: transcriptHash)
            guard case let .success(keys) = keysResult else {
                return .failure(try keysResult.unwrapErr())
            }

            let (sessionKey, clientMacKey, serverMacKey) = keys
            let clientMac = Self.createMac(key: clientMacKey, data: transcriptHash)

            var finalizeRequest = Ecliptix_Proto_Membership_OpaqueSignInFinalizeRequest()
            finalizeRequest.phoneNumber = phoneNumber
            finalizeRequest.clientEphemeralPublicKey = clientEphemeralPubKey
            finalizeRequest.clientMac = clientMac
            finalizeRequest.serverStateToken = signInResponse.serverStateToken

            return .success((finalizeRequest, sessionKey, serverMacKey, transcriptHash))
        } catch {
            return .failure(.invalidInput("Error during create sign in finalization request", inner: error))
        }
    }

    
    public func verifyServerMacAndGetSessionKey(
        response: Ecliptix_Proto_Membership_OpaqueSignInFinalizeResponse,
        sessionKey: Data, serverMacKey: Data, transcriptHash: Data
    ) -> Result<Data, OpaqueFailure> {
        let expectedServerMac = Self.createMac(key: serverMacKey, data: transcriptHash)
        let actualServerMac = response.serverMac

        guard expectedServerMac == actualServerMac else {
            return .failure(.macVerificationFailed("Server MAC verification failed."))
        }

        return .success(sessionKey)
    }
    
    static func recoverOprfKey(oprfResponse: Data, blind: UnsafePointer<BIGNUM>) -> Result<Data, OpaqueFailure> {
        let ctx = BN_CTX_new()!
        defer { BN_CTX_free(ctx) }

        // Отримуємо EC_POINT з байтів
        guard let point = EC_POINT_new(Self.getDefaultGroup()) else {
            return .failure(.pointDecodingFailed("Failed to create EC_POINT"))
        }
        defer { EC_POINT_free(point) }

        guard EC_POINT_oct2point(Self.getDefaultGroup(), point, [UInt8](oprfResponse), oprfResponse.count, ctx) == 1 else {
            return .failure(.pointDecodingFailed("Failed to decode EC_POINT"))
        }

        // Інверсія сліпого значення
        guard let order = BN_new() else {
            return .failure(.invalidInput("Failed to allocate BIGNUM for order"))
        }
        defer { BN_free(order) }

        guard EC_GROUP_get_order(Self.getDefaultGroup(), order, ctx) == 1 else {
            return .failure(.invalidInput("Failed to get group order"))
        }

        guard let blindInv = BN_new() else {
            return .failure(.invalidInput("Failed to allocate BIGNUM for inverse"))
        }
        defer { BN_free(blindInv) }

        guard BN_mod_inverse(blindInv, blind, order, ctx) != nil else {
            return .failure(.invalidInput("Failed to compute modular inverse"))
        }

        // Обчислення фінальної точки
        let finalPoint = EC_POINT_new(Self.getDefaultGroup())!
        defer { EC_POINT_free(finalPoint) }

        guard EC_POINT_mul(Self.getDefaultGroup(), finalPoint, nil, point, blindInv, ctx) == 1 else {
            return .failure(.pointMultiplicationFailed("Failed to multiply point with inverse"))
        }
        
        var compressed = Data(repeating: 0, count: 33)
        let tempWritten = UnsafeMutablePointer<UInt8>.allocate(capacity: 33)
        defer { tempWritten.deallocate() }

        let written = EC_POINT_point2oct(Self.getDefaultGroup(), finalPoint, POINT_CONVERSION_COMPRESSED,
                                         tempWritten, 33, ctx)
        compressed.replaceSubrange(0..<33, with: UnsafeBufferPointer(start: tempWritten, count: 33))


        guard written == 33 else {
            return .failure(.pointCompressionFailed("Incorrect compressed point size"))
        }

        return .success(compressed)
    }

    static func performClientAke(
        ephPrivateKey: UnsafePointer<BIGNUM>,
        statPrivateKey: UnsafePointer<BIGNUM>,
        statSPub: OpaquePointer,
        ephSPub: OpaquePointer,
    ) -> Result<Data, OpaqueFailure> {
        let ctx = BN_CTX_new()!
        defer { BN_CTX_free(ctx) }

        let dh1 = EC_POINT_new(Self.getDefaultGroup())!
        let dh2 = EC_POINT_new(Self.getDefaultGroup())!
        let dh3 = EC_POINT_new(Self.getDefaultGroup())!
        defer { EC_POINT_free(dh1); EC_POINT_free(dh2); EC_POINT_free(dh3) }

        guard EC_POINT_mul(Self.getDefaultGroup(), dh1, nil, ephSPub, ephPrivateKey, ctx) == 1,
              EC_POINT_mul(Self.getDefaultGroup(), dh2, nil, statSPub, ephPrivateKey, ctx) == 1,
              EC_POINT_mul(Self.getDefaultGroup(), dh3, nil, ephSPub, statPrivateKey, ctx) == 1 else {
            return .failure(.pointCompressionFailed("AKE failed"))
        }

        func compressedHex(_ point: OpaquePointer) -> String {
            var buf = Data(repeating: 0, count: 33)
            let bufCount = buf.count
            buf.withUnsafeMutableBytes {
                _ = EC_POINT_point2oct(Self.getDefaultGroup(), point, POINT_CONVERSION_COMPRESSED,
                                       $0.baseAddress?.assumingMemoryBound(to: UInt8.self),
                                       bufCount, ctx)
            }
            return buf.map { String(format: "%02x", $0) }.joined()
        }

        print("Swift dh1:", compressedHex(dh1))
        print("Swift dh2:", compressedHex(dh2))
        print("Swift dh3:", compressedHex(dh3))

        let length = 33
        var out = Data(repeating: 0, count: length * 3)
        out.withUnsafeMutableBytes { ptr in
            let base = ptr.baseAddress!.assumingMemoryBound(to: UInt8.self)
            EC_POINT_point2oct(Self.getDefaultGroup(), dh1, POINT_CONVERSION_COMPRESSED, base, length, ctx)
            EC_POINT_point2oct(Self.getDefaultGroup(), dh2, POINT_CONVERSION_COMPRESSED, base + length, length, ctx)
            EC_POINT_point2oct(Self.getDefaultGroup(), dh3, POINT_CONVERSION_COMPRESSED, base + 2 * length, length, ctx)
        }

        return .success(out)
    }
    
    public func hashTranscript(
        phoneNumber: String,
        oprfResponse: Data,
        clientStaticPublicKey: Data,
        clientEphemeralPublicKey: Data,
        serverStaticPublicKey: Data,
        serverEphemeralPublicKey: Data
    ) -> Data {
        let ctx = EVP_MD_CTX_new()!
        defer { EVP_MD_CTX_free(ctx) }

        EVP_DigestInit_ex(ctx, EVP_sha256(), nil)

        func update(_ data: Data) {
            _ = data.withUnsafeBytes {
                EVP_DigestUpdate(ctx, $0.baseAddress, data.count)
            }
        }

        update(OpaqueConstants.protocolVersion)
        update(Data(phoneNumber.utf8))
        update(oprfResponse)
        update(clientStaticPublicKey)
        update(clientEphemeralPublicKey)
        update(serverStaticPublicKey)
        update(serverEphemeralPublicKey)

        var hash = Data(repeating: 0, count: Int(SHA256.Digest.byteCount))
        _ = hash.withUnsafeMutableBytes {
            EVP_DigestFinal_ex(ctx, $0.baseAddress?.assumingMemoryBound(to: UInt8.self), nil)
        }

        return hash
    }

    
    public static func deriveFinalKeys(akeResult: Data, transcriptHash: Data) -> Result<(sessionKey: Data, clientMacKey: Data, serverMacKey: Data), OpaqueFailure> {
        do {
            let prkResult = OpaqueCryptoUtilities.hkdfExtract(ikm: akeResult, salt: OpaqueConstants.akeSalt)

            guard case .success(let prk) = prkResult else {
                return .failure(try prkResult.unwrapErr())
            }

            var infoBuffer = Data(count: OpaqueConstants.sessionKeyInfo.count + transcriptHash.count)
            infoBuffer.replaceSubrange(OpaqueConstants.sessionKeyInfo.count..<infoBuffer.count, with: transcriptHash)
            
            infoBuffer.replaceSubrange(0..<OpaqueConstants.sessionKeyInfo.count, with: OpaqueConstants.sessionKeyInfo)
            let sessionKey = OpaqueCryptoUtilities.hkdfExpand(prk: prk, info: infoBuffer, outputLength: OpaqueConstants.macKeyLength)

            infoBuffer.replaceSubrange(0..<OpaqueConstants.clientMacKeyInfo.count, with: OpaqueConstants.clientMacKeyInfo)
            let clientMacKey = OpaqueCryptoUtilities.hkdfExpand(prk: prk, info: infoBuffer, outputLength: OpaqueConstants.macKeyLength)

            infoBuffer.replaceSubrange(0..<OpaqueConstants.serverMacKeyInfo.count, with: OpaqueConstants.serverMacKeyInfo)
            let serverMacKey = OpaqueCryptoUtilities.hkdfExpand(prk: prk, info: infoBuffer, outputLength: OpaqueConstants.macKeyLength)

            return .success((sessionKey, clientMacKey, serverMacKey))
        } catch {
            return .failure(error as! OpaqueFailure)
        }
    }
    
    public static func createMac(key: Data, data: Data) -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)
        return hmac.withUnsafeBytes { Data($0) }
    }
    
    private func decodeCompressedPoint(_ data: Data, group: OpaquePointer) -> OpaquePointer? {
        guard let point = EC_POINT_new(group) else { return nil }
        let result = data.withUnsafeBytes {
            EC_POINT_oct2point(group, point, $0.baseAddress?.assumingMemoryBound(to: UInt8.self), data.count, nil)
        }
        return result == 1 ? point : nil
    }

    private func privateKeyToBignum(_ privateKey: P256.KeyAgreement.PrivateKey) -> UnsafeMutablePointer<BIGNUM>? {
        let raw = privateKey.rawRepresentation
        return BN_bin2bn([UInt8](raw), Int32(raw.count), nil)
    }
}
