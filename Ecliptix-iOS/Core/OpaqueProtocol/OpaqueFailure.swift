//
//  OpaqueFailure.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 26.06.2025.
//

enum OpaqueFailureType: Error {
    case hashingValidPointFailed
    case decryptFailure
    case encryptFailure
    case invalidInput
    case invalidKeySignature
    case macVerificationFailed
    
    case pointCompressionFailed
    case pointDecodingFailed
    case pointMultiplicationFailed
    
    case hashFailed
}

struct OpaqueFailure: Error {
    let type: OpaqueFailureType
    let message: String
    let innerError: Error?
    
    private init(type: OpaqueFailureType, message: String, innerError: Error? = nil) {
        self.type = type
        self.message = message
        self.innerError = innerError
    }
    
    static func macVerificationFailed(_ details: String? = nil, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .macVerificationFailed,
            message: details?.isEmpty != false ? OpaqueMessageKeys.macVerificationFailed : details!,
            innerError: inner
        )
    }

    static func invalidKeySignature(_ details: String, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .invalidKeySignature,
            message: details,
            innerError: inner
        )
    }

    static func hashingValidPointFailed(_ details: String? = nil, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .hashingValidPointFailed,
            message: details?.isEmpty != false ? OpaqueMessageKeys.hashingValidPointFailed : details!,
            innerError: inner
        )
    }

    static func decryptFailed(_ details: String? = nil, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .decryptFailure,
            message: details?.isEmpty != false ? OpaqueMessageKeys.decryptFailed : details!,
            innerError: inner
        )
    }

    static func encryptFailed(_ details: String? = nil, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .encryptFailure,
            message: details?.isEmpty != false ? OpaqueMessageKeys.encryptFailed : details!,
            innerError: inner
        )
    }

    static func invalidInput(_ details: String? = nil, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .invalidInput,
            message: details?.isEmpty != false ? OpaqueMessageKeys.inputKeyingMaterialCannotBeNullOrEmpty : details!,
            innerError: inner
        )
    }
    
    static func pointCompressionFailed(_ details: String? = nil, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .pointCompressionFailed,
            message: details?.isEmpty != false ? OpaqueMessageKeys.pointCompressionFailed : details!,
            innerError: inner
        )
    }
    
    static func pointDecodingFailed(_ details: String, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .pointDecodingFailed,
            message: details,
            innerError: inner
        )
    }
    
    static func pointMultiplicationFailed(_ details: String, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .pointMultiplicationFailed,
            message: details,
            innerError: inner
        )
    }
    
    static func hashFailed(_ details: String, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .hashFailed,
            message: details,
            innerError: inner
        )
    }
}
