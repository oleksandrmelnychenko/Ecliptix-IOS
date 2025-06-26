//
//  Constants.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 22.05.2025.
//

import Foundation

public struct Constants {
    // Key sizes
    public static let x25519KeySize = 32
    public static let cacheWindowSize: UInt32 = 1000
    public static let ed25519KeySize = 32
    
    // HKDF Info constants (represented as [UInt8])
    public static let msgInfo: Data = Data([0x01])
    public static let chainInfo: Data = Data([0x02])
    public static let x3dhInfo: Data = Data(
        [0x45, 0x63, 0x6c, 0x69, 0x70, 0x74, 0x69, 0x78, 0x5f, 0x58, 0x33, 0x44, 0x48]
    )

    public static let ed25519PublicKeySize = 32
    public static let ed25519SecretKeySize = 64
    public static let ed25519SignatureSize = 64
    public static let x25519PublicKeySize = 32
    public static let x25519PrivateKeySize = 32
    public static let aesKeySize = 32
    public static let aesGcmNonceSize = 12
    public static let aesGcmTagSize = 16

    public static let ephemeralDhRatchet: Data = Data(
        [0x45, 0x70, 0x68, 0x65, 0x6d, 0x65, 0x72, 0x61, 0x6c, 0x20, 0x44, 0x48, 0x20, 0x52, 0x61, 0x74, 0x63, 0x68, 0x65, 0x74]
    )
}
