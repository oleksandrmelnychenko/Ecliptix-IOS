//
//  InternalValidationFailure.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 23.07.2025.
//



struct InternalValidationFailure: Error, CustomStringConvertible {
    let type: InternalValidationFailureType
    let message: String
    let error: Error?
    
    var description: String {
        var desc = "[\(type)] \(message)"
        if let error = error {
            desc += " | inner: \(error)"
        }
        return desc
    }
    
    private init(type: InternalValidationFailureType, message: String, error: Error?) {
        self.type = type
        self.message = message
        self.error = error
    }
    
    public static func deviceIdUnavailable(_ details: String, inner: Error? = nil) -> InternalValidationFailure {
        .init(type: .deviceIdUnavailable, message: details, error: inner)
    }
    
    public static func invalidValue(_ details: String, inner: Error? = nil) -> InternalValidationFailure {
        .init(type: .invalidValue, message: details, error: inner)
    }
    
    public static func phoneNumberIsGuid(_ details: String, inner: Error? = nil) -> InternalValidationFailure {
        .init(type: .phoneNumberIsGuid, message: details, error: inner)
    }
    
    public static func secureStoreError(_ details: String, inner: Error? = nil) -> InternalValidationFailure {
        .init(type: .secureStoreError, message: details, error: inner)
    }
    
    public static func internalServiceApi(_ details: String, inner: Error? = nil) -> InternalValidationFailure {
        .init(type: .internalServiceApi, message: details, error: inner)
    }
    
    public static func networkError(_ details: String, inner: Error? = nil) -> InternalValidationFailure {
        .init(type: .networkError, message: details, error: inner)
    }
    
    public static func unknown(_ details: String, inner: Error? = nil) -> InternalValidationFailure {
        .init(type: .unknown, message: details, error: inner)
    }
}

