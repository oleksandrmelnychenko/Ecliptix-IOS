//
//  NetworkFailure.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.07.2025.
//

import Foundation

public struct NetworkFailure: Error, FailureBaseProtocol {
    let failureType: NetworkFailureType
    let message: String
    let innerError: Error?
    
    func toStructuredLog() -> Any {
        return [
            "networkFailureType": String(describing: failureType),
            "message": message,
            "innerError": innerError?.localizedDescription ?? "nil",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
    }
    
    public static func invalidRequestType(_ details: String, inner: Error? = nil) -> NetworkFailure {
        NetworkFailure(failureType: .invalidRequestType, message: details, innerError: inner)
    }
    
    public static func dataCenterNotResponding(_ details: String, inner: Error? = nil) -> NetworkFailure {
        NetworkFailure(failureType: .dataCenterNotResponding, message: details, innerError: inner)
    }
    
    public static func dataCenterShutdown(_ details: String, inner: Error? = nil) -> NetworkFailure {
        NetworkFailure(failureType: .dataCenterShutdown, message: details, innerError: inner)
    }
    
    public static func serverErrrorResponse(_ details: String, inner: Error? = nil) -> NetworkFailure {
        NetworkFailure(failureType: .serverErrrorResponse, message: details, innerError: inner)
    }
    
    public static func unexpectedError(_ details: String, inner: Error? = nil) -> NetworkFailure {
        NetworkFailure(failureType: .unexpectedError, message: details, innerError: inner)
    }
    
    func toInternalValidationFailure() -> InternalValidationFailure {
        switch self.failureType {
        case .dataCenterNotResponding:
            .networkError(self.message, inner: self.innerError)
        case .dataCenterShutdown:
            .networkError(self.message, inner: self.innerError)
        case .invalidRequestType:
            .networkError(self.message, inner: self.innerError)
        case .ecliptixProtocolFailure:
            .networkError(self.message, inner: self.innerError)
        case .serverErrrorResponse:
            .networkError(self.message, inner: self.innerError)
        case .unexpectedError:
            .unknown(self.message, inner: self.innerError)
        }
    }
}
