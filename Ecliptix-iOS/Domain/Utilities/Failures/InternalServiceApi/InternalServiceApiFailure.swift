//
//  InternalServiceApiFailure.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 02.07.2025.
//

import Security
import Foundation

struct InternalServiceApiFailure: Error, CustomStringConvertible, FailureBaseProtocol {
    let type: InternalServiceApiFailureType
    let message: String
    let innerError: Error?
    
    var description: String {
        var desc = "[\(type)] \(message)"
        if let error = innerError {
            desc += " | inner: \(error)"
        }
        return desc
    }
    
    private init(type: InternalServiceApiFailureType, message: String, error: Error?) {
        self.type = type
        self.message = message
        self.innerError = error
    }
    
    static func fromOSStatus(_ status: OSStatus, context: String) -> InternalServiceApiFailure {
        switch status {
        case errSecItemNotFound:
            return .secureStoreKeyNotFound(context)
        case errSecAuthFailed:
            return .secureStoreAccessDenied(context)
        case errSecMissingEntitlement:
            return .secureStoreAccessDenied("\(context) | Missing Entitlement")
        default:
            return .secureStoreUnknown("\(context) | OSStatus: \(status)")
        }
    }
    
    func toStructuredLog() -> Any {
        return [
            "protocolFailureType": String(describing: type),
            "message": message,
            "innerError": innerError?.localizedDescription ?? "nil",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
    }
        
    static func secureStoreNotFound(_ details: String, inner: Error? = nil) -> InternalServiceApiFailure {
        return InternalServiceApiFailure(
            type: .secureStoreNotFound,
            message: details,
            error: inner)
    }
    
    static func secureStoreKeyNotFound(_ details: String, inner: Error? = nil) -> InternalServiceApiFailure {
        return InternalServiceApiFailure(
            type: .secureStoreKeyNotFound,
            message: details,
            error: inner
        )
    }
    
    static func secureStoreAccessDenied(_ details: String, inner: Error? = nil) -> InternalServiceApiFailure {
        return InternalServiceApiFailure(
            type: .secureStoreAccessDenied,
            message: details,
            error: inner
        )
    }
    
    static func secureStoreUnknown(_ details: String, inner: Error? = nil) -> InternalServiceApiFailure {
        return InternalServiceApiFailure(
            type: .secureStoreUnknown,
            message: details,
            error: inner
        )
    }
    
    static func dependencyResolution(_ details: String, inner: Error? = nil) -> InternalServiceApiFailure {
        return InternalServiceApiFailure(
            type: .dependencyResolution,
            message: details,
            error: inner
        )
    }
    
    static func deserialization(_ details: String, inner: Error? = nil) -> InternalServiceApiFailure {
        return InternalServiceApiFailure(
            type: .deserialization,
            message: details,
            error: inner
        )
    }
    
    func toInternalValidationFailure() -> InternalValidationFailure {
        switch self.type {
        case .secureStoreNotFound:
            .secureStoreError(self.message, inner: self.innerError)
        case .secureStoreKeyNotFound:
            .secureStoreError(self.message, inner: self.innerError)
        case .secureStoreAccessDenied:
            .secureStoreError(self.message, inner: self.innerError)
        case .secureStoreUnknown:
            .secureStoreError(self.message, inner: self.innerError)
        case .dependencyResolution:
            .internalServiceApi(self.message, inner: self.innerError)
        case .deserialization:
            .internalServiceApi(self.message, inner: self.innerError)
        }
    }
}
