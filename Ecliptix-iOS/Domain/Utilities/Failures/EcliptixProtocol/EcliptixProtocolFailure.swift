//
//  ShieldFailure.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 22.05.2025.
//

import Foundation
import GRPC

public struct EcliptixProtocolFailure: CustomStringConvertible, Equatable, Hashable, Error, LocalizedError, FailureBaseProtocol {
    let failureType: EcliptixProtocolFailureType
    let message: String
    let innerError: Error?
    
    private init(type: EcliptixProtocolFailureType, message: String, innerError: Error? = nil) {
        self.failureType = type
        self.message = message
        self.innerError = innerError
    }
    
    public var errorDescription: String? {
        return message
    }
    
    func toStructuredLog() -> Any {
        return [
            "protocolFailureType": String(describing: failureType),
            "message": message,
            "innerError": innerError?.localizedDescription ?? "nil",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
    }
    
    // MARK: - Factory Methods
    static func generic(_ details: String? = nil, inner: Error? = nil) -> EcliptixProtocolFailure {
        return EcliptixProtocolFailure(type: .generic, message: details ?? "An unspecified error occurred.", innerError: inner)
    }

    static func decode(_ details: String, inner: Error? = nil) -> EcliptixProtocolFailure {
        return EcliptixProtocolFailure(type: .decodeFailed, message: details, innerError: inner)
    }

    static func deriveKey(_ details: String, inner: Error? = nil) -> EcliptixProtocolFailure {
        return EcliptixProtocolFailure(type: .deriveKeyFailed, message: details, innerError: inner)
    }

    static func handshake(_ details: String, inner: Error? = nil) -> EcliptixProtocolFailure {
        return EcliptixProtocolFailure(type: .handshakeFailed, message: details, innerError: inner)
    }

    static func peerPubKey(_ details: String, inner: Error? = nil) -> EcliptixProtocolFailure {
        return EcliptixProtocolFailure(type: .peerPubKeyFailed, message: details, innerError: inner)
    }

    static func invalidInput(_ details: String) -> EcliptixProtocolFailure {
        return EcliptixProtocolFailure(type: .invalidInput, message: details)
    }

    static func objectDisposed(_ resourceName: String) -> EcliptixProtocolFailure {
        return EcliptixProtocolFailure(type: .objectDisposed, message: "Cannot access disposed resource '\(resourceName)'.")
    }

    static func allocationFailed(_ details: String, inner: Error? = nil) -> EcliptixProtocolFailure {
        return EcliptixProtocolFailure(type: .allocationFailed, message: details, innerError: inner)
    }

    static func pinningFailure(_ details: String, inner: Error? = nil) -> EcliptixProtocolFailure {
        return EcliptixProtocolFailure(type: .pinningFailure, message: details, innerError: inner)
    }

    static func bufferTooSmall(_ details: String) -> EcliptixProtocolFailure {
        return EcliptixProtocolFailure(type: .bufferTooSmall, message: details)
    }

    static func dataTooLarge(_ details: String) -> EcliptixProtocolFailure {
        return EcliptixProtocolFailure(type: .dataTooLarge, message: details)
    }
    
    static func keyGeneration(_ details: String, inner: Error? = nil) -> EcliptixProtocolFailure {
        return EcliptixProtocolFailure(type: .keyGenerationFailed, message: details, innerError: inner)
    }
    
    static func prepareLocal(_ details: String, inner: Error? = nil) -> EcliptixProtocolFailure {
        return EcliptixProtocolFailure(type: .prepareBufferError, message: details, innerError: inner)
    }
    
    static func memoryBufferError(_ details: String, inner: Error? = nil) -> EcliptixProtocolFailure {
        return EcliptixProtocolFailure(type: .memoryBufferError, message: details, innerError: inner)
    }
    
    static func unexpectedError(_ details: String, inner: Error? = nil) -> EcliptixProtocolFailure {
        return EcliptixProtocolFailure(type: .unexpectedError, message: details, innerError: inner)
    }

    // MARK: - Description / Debug
    public var description: String {
        let inner = innerError.map { "\($0)" } ?? "nil"
        return "ShieldFailure(type: \(failureType), message: '\(message)', innerError: \(inner))"
    }

    // MARK: - Equatable
    public static func == (lhs: EcliptixProtocolFailure, rhs: EcliptixProtocolFailure) -> Bool {
        return lhs.failureType == rhs.failureType && lhs.message == rhs.message && String(describing: lhs.innerError) == String(describing: rhs.innerError)
    }

    // MARK: - Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(failureType)
        hasher.combine(message)
        hasher.combine(innerError?.localizedDescription)
    }
    
    public func toNetworkFailure() -> NetworkFailure {
        let networkFailureType: NetworkFailureType = {
            switch self.failureType {
            default:
                return .ecliptixProtocolFailure
            }
        }()
        
        return NetworkFailure(failureType: networkFailureType, message: self.message, innerError: self.innerError)
    }
}
