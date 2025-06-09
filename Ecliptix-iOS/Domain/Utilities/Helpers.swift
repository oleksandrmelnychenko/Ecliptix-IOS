//
//  Helpers.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 22.05.2025.
//

import Foundation
import CryptoKit
import SwiftProtobuf

enum HelpersError: LocalizedError {
    case invalidTagLength
    case randomBytesFailed(OSStatus)
    case emptyDestinationBuffer
    case protobufParsingFailed(String)
    case invalidPayloadDataLength
    
    var errorDescription: String {
        switch self {
        case .invalidTagLength:
            return "tagLengthBytes must be > 0"
        case .randomBytesFailed(let status):
            return "Failed to generate random bytes with status \(status)"
        case .emptyDestinationBuffer:
            return "Destination buffer cannot be empty"
        case .protobufParsingFailed(let message):
            return "Failed to parse protobuf message: \(message)"
        case .invalidPayloadDataLength:
            return "Invalid payload data length."
        }
    }
}

public struct Helpers {
    private static let fullUInt32Range = UInt32.min...UInt32.max
    
    // Generate a random UInt32, optionally excluding zero
    public static func generateRandomUInt32(excludeZero: Bool = false) -> UInt32 {
        var value: UInt32 = 0
        
        repeat {
            value = UInt32.random(in: fullUInt32Range)
        } while excludeZero && value == 0
        
        return value
    }
    
    public static func parseFromBytes<T: SwiftProtobuf.Message>(_ type: T.Type, data: Data) throws -> T {
        do {
            return try T(serializedBytes: [UInt8](data))
        } catch {
            throw HelpersError.protobufParsingFailed(error.localizedDescription)
        }
    }
    
    
    

    // Generate a secure random tag (byte array) of given length
//    public static func generateSecureRandomTag(tagLengthBytes: Int) throws -> [UInt8] {
//        guard tagLengthBytes > 0 else {
//            throw HelpersError.invalidTagLength
//        }
//        var bytes = [UInt8](repeating: 0, count: tagLengthBytes)
//        let result = SecRandomCopyBytes(kSecRandomDefault, tagLengthBytes, &bytes)
//        if result != errSecSuccess {
//            throw HelpersError.randomBytesFailed(result)
//        }
//        return bytes
//    }
//
//    // Fill a given UnsafeMutableRawBufferPointer with secure random bytes
//    internal static func generateSecureRandomTag(destination: UnsafeMutableRawBufferPointer) throws {
//        guard !destination.isEmpty else {
//            throw HelpersError.emptyDestinationBuffer
//        }
//        let result = SecRandomCopyBytes(kSecRandomDefault, destination.count, destination.baseAddress!)
//        if result != errSecSuccess {
//            throw HelpersError.randomBytesFailed(result)
//        }
//    }
}
