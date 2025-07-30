//
//  OpaqueFailure.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 26.06.2025.
//

enum OpaqueFailureType {
    // General
    case invalidInput
    case hashToPointFailed
    case digestComputationFailed

    // Encryption
    case encryptFailure
    case decryptFailure
    case macVerificationFailed

    // EC Point
    case pointCompressionFailed
    case pointDecodingFailed
    case pointMultiplicationFailed
    case pointNotOnCurve
    case invalidEcGroup
    case modularInverseFailed
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
    
    static func invalidInput(_ details: String, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .invalidInput,
            message: details,
            innerError: inner
        )
    }
    
    static func hashToPointFailed(_ details: String, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .hashToPointFailed,
            message: details,
            innerError: inner
        )
    }
    
    static func digestComputationFailed(_ details: String, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .digestComputationFailed,
            message: details,
            innerError: inner
        )
    }

    static func encryptFailed(_ details: String, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .encryptFailure,
            message: details,
            innerError: inner
        )
    }
    
    static func decryptFailed(_ details: String, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .decryptFailure,
            message: details,
            innerError: inner
        )
    }
    
    static func macVerificationFailed(_ details: String, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .macVerificationFailed,
            message: details,
            innerError: inner
        )
    }
    
    static func pointCompressionFailed(_ details: String, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .pointCompressionFailed,
            message: details,
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
    
    static func pointNotOnCurve(_ details: String, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .pointNotOnCurve,
            message: details,
            innerError: inner
        )
    }

    static func invalidEcGroup(_ details: String, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .pointNotOnCurve,
            message: details,
            innerError: inner
        )
    }

    static func modularInverseFailed(_ details: String, inner: Error? = nil) -> OpaqueFailure {
        return OpaqueFailure(
            type: .pointNotOnCurve,
            message: details,
            innerError: inner
        )
    }
    
    func toInternalValidationFailure() -> InternalValidationFailure {
        switch self.type {
            
        case .invalidInput:
            .opaqueError(self.message, inner: self.innerError)
        case .hashToPointFailed:
            .opaqueError(self.message, inner: self.innerError)
        case .digestComputationFailed:
            .opaqueError(self.message, inner: self.innerError)
        case .encryptFailure:
            .opaqueError(self.message, inner: self.innerError)
        case .decryptFailure:
            .opaqueError(self.message, inner: self.innerError)
        case .macVerificationFailed:
            .opaqueError(self.message, inner: self.innerError)
        case .pointCompressionFailed:
            .opaqueError(self.message, inner: self.innerError)
        case .pointDecodingFailed:
            .opaqueError(self.message, inner: self.innerError)
        case .pointMultiplicationFailed:
            .opaqueError(self.message, inner: self.innerError)
        case .pointNotOnCurve:
            .opaqueError(self.message, inner: self.innerError)
        case .invalidEcGroup:
            .opaqueError(self.message, inner: self.innerError)
        case .modularInverseFailed:
            .opaqueError(self.message, inner: self.innerError)
        }
    }
}
