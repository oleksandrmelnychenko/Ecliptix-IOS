//
//  SodiumFailure.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 05.06.2025.
//

import Foundation

enum SodiumFailureType {
    case initialzationFailed
    case libraryNotFound
    case allocationFailed
    case memoryPinningFailed
    case secureWipeFailed
    case invalidBufferSize
    case bufferTooSmall
    case bufferTooLarge
    case nilPointer
    case memoryProtectionFailed
    
//    var errorDescription: String {
//        switch self {
//        case .initialzationFailed:
//            return "Failed to initialize libsodium library."
//        case .libraryNotFound(let library):
//            return "Failed load \(library). Ensure the native library is available and compatible."
//        case .allocationFailed:
//            return "."
//        case .memoryPinningFailed:
//            return "."
//        case .secureWipeFailed:
//            return "."
//        case .invalidBufferSize:
//            return "."
//        case .bufferTooSmall:
//            return "."
//        case .bufferTooLarge:
//            return "."
//        case .nilPointer:
//            return "."
//        case .memoryProtectionFailed:
//            return "."
//        }
//    }
}

public struct SodiumFailure: CustomStringConvertible, Equatable, Hashable, Error, LocalizedError {
    let type: SodiumFailureType
    let message: String
    let innerError: Error?
    
    private init(type: SodiumFailureType, message: String, innerError: Error? = nil) {
        self.type = type
        self.message = message
        self.innerError = innerError
    }
    
    public var errorDescription: String? {
        return message
    }
    
    // MARK: - Factory Methods
    static func initializationFailed(_ details: String, inner: Error? = nil) -> SodiumFailure {
        return SodiumFailure(type: .initialzationFailed, message: details, innerError: inner)
    }
    
    static func libraryNotFound(_ details: String, inner: Error? = nil) -> SodiumFailure {
        return SodiumFailure(type: .libraryNotFound, message: details, innerError: inner)
    }
    
    static func allocationFailed(_ details: String, inner: Error? = nil) -> SodiumFailure {
        return SodiumFailure(type: .allocationFailed, message: details, innerError: inner)
    }
    
    static func memoryPinningFailed(_ details: String, inner: Error? = nil) -> SodiumFailure {
        return SodiumFailure(type: .memoryPinningFailed, message: details, innerError: inner)
    }
    
    static func secureWipeFailed(_ details: String, inner: Error? = nil) -> SodiumFailure {
        return SodiumFailure(type: .secureWipeFailed, message: details, innerError: inner)
    }
    
    static func memoryProtectionFailed(_ details: String, inner: Error? = nil) -> SodiumFailure {
        return SodiumFailure(type: .memoryProtectionFailed, message: details, innerError: inner)
    }
    
    static func nilPointer(_ details: String) -> SodiumFailure {
        return SodiumFailure(type: .nilPointer, message: details)
    }
    
    static func invalidBufferSize(_ details: String) -> SodiumFailure {
        return SodiumFailure(type: .invalidBufferSize, message: details)
    }
    
    static func bufferTooSmall(_ details: String) -> SodiumFailure {
        return SodiumFailure(type: .bufferTooSmall, message: details)
    }
    
    static func bufferTooLarge(_ details: String) -> SodiumFailure {
        return SodiumFailure(type: .bufferTooLarge, message: details)
    }
    
    // MARK: - Description / Debug
    public var description: String {
        let inner = innerError.map { "\($0)" } ?? "nil"
        return "SodiumFailure(type: \(type), message: '\(message)', innerError: \(inner))"
    }

    // MARK: - Equatable
    public static func == (lhs: SodiumFailure, rhs: SodiumFailure) -> Bool {
        return lhs.type == rhs.type && lhs.message == rhs.message && String(describing: lhs.innerError) == String(describing: rhs.innerError)
    }

    // MARK: - Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(message)
        hasher.combine(innerError?.localizedDescription)
    }
}

extension SodiumFailure {
    func toEcliptixProtocolFailure() -> EcliptixProtocolFailure {
        switch self.type {
        case .initialzationFailed:
            return .generic(self.message, inner: self.innerError)
        case .libraryNotFound:
            return .generic(self.message, inner: self.innerError)
        case .allocationFailed:
            return .allocationFailed(self.message, inner: self.innerError)
        case .memoryPinningFailed:
            return .pinningFailure(self.message, inner: self.innerError)
        case .secureWipeFailed:
            return .memoryBufferError(self.message, inner: self.innerError)
        case .memoryProtectionFailed:
            return .memoryBufferError(self.message, inner: self.innerError)
        case .nilPointer:
            return .objectDisposed(self.message)
        case .invalidBufferSize:
            return .invalidInput(self.message)
        case .bufferTooSmall:
            return .bufferTooSmall(self.message)
        case .bufferTooLarge:
            return .dataTooLarge(self.message)
        }
    }
}


