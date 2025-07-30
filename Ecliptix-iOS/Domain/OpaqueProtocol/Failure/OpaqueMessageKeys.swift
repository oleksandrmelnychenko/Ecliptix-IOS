//
//  OpaqueMessageKeys.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 26.06.2025.
//

enum OpaqueMessageKeys {
    static let inputKeyingMaterialCannotBeNullOrEmpty = "Opaque input keying material (ikm) cannot be null or empty"
    static let invalidKeySignature = "Opaque invalid key signature"
    static let hashingValidPointFailed = "Opaque Failed to hash input to a valid curve point after 255 attempts."
    static let decryptFailed = "Opaque decryption failed"
    static let encryptFailed = "Opaque encryption failed"
    static let tokenExpired = "Opaque token has expired"
    static let macVerificationFailed = "Opaque MAC verification failed"
    static let pointCompressionFailed = "Opaque point compression failed"
}
