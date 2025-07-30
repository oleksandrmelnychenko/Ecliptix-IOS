//
//  OpaqueConstants 2.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 28.07.2025.
//


import Foundation
import CryptoKit

enum OpaqueConstants {
    // MARK: - Protocol Version
    static let protocolVersion = Data("Ecliptix-OPAQUE-v1".utf8)

    // MARK: - HKDF Info Labels
    static let credentialKeyInfo = Data("Ecliptix-OPAQUE-CredentialKey".utf8)
    static let akeSalt           = Data("OPAQUE-AKE-Salt".utf8)
    static let sessionKeyInfo    = Data("session_key".utf8)
    static let clientMacKeyInfo  = Data("client_mac_key".utf8)
    static let serverMacKeyInfo  = Data("server_mac_key".utf8)

    // MARK: - Key Sizes
    static let defaultKeyLength = 32 // 256-bit key
    static let macKeyLength = 32
    static let ecCompressedPointLength = 33
    static let bnScalarByteLength = 32 // EC scalar field size in bytes

    // MARK: - AES-GCM Parameters
    static let aesGcmNonceLengthBytes  = 12
    static let aesGcmTagLengthBits     = 128
    static let aesGcmTagLengthBytes    = aesGcmTagLengthBits / 8

    // MARK: - Hashing
    static let sha256DigestLength = SHA256.Digest.byteCount

    // MARK: - EC Point Compression
    static let ecCompressedPrefixEven: UInt8 = 0x02
}

