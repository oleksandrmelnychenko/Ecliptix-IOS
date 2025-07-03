//
//  InternalServiceApiFailure.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 02.07.2025.
//

import Security

enum InternalServiceApiFailureType {
    case secureStoreNotFound
    case secureStoreKeyNotFound
    case secureStoreAccessDenied
    case secureStoreUnknown
}

struct InternalServiceApiFailure: Error, CustomStringConvertible {
    let type: InternalServiceApiFailureType
    let message: String
    let error: Error?
    
    var description: String {
        var desc = "[\(type)] \(message)"
        if let error = error {
            desc += " | inner: \(error)"
        }
        return desc
    }
    
    private init(type: InternalServiceApiFailureType, message: String, error: Error?) {
        self.type = type
        self.message = message
        self.error = error
    }
    
    static func fromOSStatus(_ status: OSStatus, context: String) -> InternalServiceApiFailure {
        switch status {
        case errSecItemNotFound:
            return .secureStoreKeyNotFound(details: context)
        case errSecAuthFailed:
            return .secureStoreAccessDenied(details: context)
        case errSecMissingEntitlement:
            return .secureStoreAccessDenied(details: "\(context) | Missing Entitlement")
        default:
            return .secureStoreUnknown(details: "\(context) | OSStatus: \(status)")
        }
    }
    
    static func secureStoreNotFound(details: String, inner: Error? = nil) -> InternalServiceApiFailure {
        return InternalServiceApiFailure(
            type: .secureStoreNotFound,
            message: details,
            error: inner)
    }
    
    static func secureStoreKeyNotFound(details: String, inner: Error? = nil) -> InternalServiceApiFailure {
        return InternalServiceApiFailure(
            type: .secureStoreKeyNotFound,
            message: details,
            error: inner
        )
    }
    
    static func secureStoreAccessDenied(details: String, inner: Error? = nil) -> InternalServiceApiFailure {
        return InternalServiceApiFailure(
            type: .secureStoreAccessDenied,
            message: details,
            error: inner
        )
    }
    
    static func secureStoreUnknown(details: String, inner: Error? = nil) -> InternalServiceApiFailure {
        return InternalServiceApiFailure(
            type: .secureStoreUnknown,
            message: details,
            error: inner
        )
    }
}
