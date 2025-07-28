//
//  OpaqueConstants 2.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 28.07.2025.
//


import Foundation

enum OpaqueConstants {
    static let credentialKeyInfo = Data("Ecliptix-OPAQUE-CredentialKey".utf8)
    static let akeSalt = Data("OPAQUE-AKE-Salt".utf8)
    static let sessionKeyInfo = Data("session_key".utf8)
    static let clientMacKeyInfo = Data("client_mac_key".utf8)
    static let serverMacKeyInfo = Data("server_mac_key".utf8)
    static let protocolVersion = Data("Ecliptix-OPAQUE-v1".utf8)

    static let ecCompressedPointLength = 33
    static let defaultKeyLength = 32
    static let macKeyLength = 32

    static let aesGcmNonceLengthBytes = 12
    static let aesGcmTagLengthBits = 128
}
