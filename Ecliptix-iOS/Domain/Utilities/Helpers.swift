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
    
    public static func generateRandomUInt32(excludeZero: Bool = false) -> UInt32 {
        var value: UInt32 = 0
        
        repeat {
            value = UInt32.random(in: fullUInt32Range)
        } while excludeZero && value == 0
        
        return value
    }
    
    public static func generateRandomUInt32(in range: ClosedRange<UInt32>) -> UInt32 {
        return UInt32.random(in: range)
    }
    
    public static func guidToData(_ uuid: UUID) -> Data {
        var data = withUnsafeBytes(of: uuid.uuid) { Data($0) }

        swapBytes(in: &data, at: 0, and: 3)
        swapBytes(in: &data, at: 1, and: 2)
        swapBytes(in: &data, at: 4, and: 5)
        swapBytes(in: &data, at: 6, and: 7)

        return data
    }
    
    public static func fromDataToGuid(_ data: Data) throws -> UUID {
        guard data.count == 16 else {
            throw HelpersError.invalidPayloadDataLength
        }

        return data.withUnsafeBytes { buffer -> UUID in
            let uuid = buffer.bindMemory(to: uuid_t.self)
            return UUID(uuid: uuid[0])
        }
    }
    
    public static func parseFromBytes<T: SwiftProtobuf.Message>(_ type: T.Type, data: Data) throws -> T {
        do {
            return try T(serializedBytes: [UInt8](data))
        } catch {
            throw HelpersError.protobufParsingFailed(error.localizedDescription)
        }
    }
    
    public static func computeUniqueConnectId(
        appInstanceId: Data,
        appDeviceId: Data,
        contextType: Ecliptix_Proto_PubKeyExchangeType,
        operationContextId: UUID? = nil
    ) -> UInt32 {
        var buffer = Data()
        buffer.append(appInstanceId)
        buffer.append(appDeviceId)

        var contextTypeBE = UInt32(contextType.rawValue).bigEndian
        withUnsafeBytes(of: &contextTypeBE) { buffer.append(contentsOf: $0) }

        if let opId = operationContextId {
            buffer.append(Self.guidToData(opId))
        }

        let hash = SHA256.hash(data: buffer)

        let prefix = Data(hash.prefix(4))
        return prefix.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
    }
    
    /// Generate a secure random tag (byte array) of given length
    public static func generateSecureRandomTag(tagLengthBytes: Int) throws -> [UInt8] {
        guard tagLengthBytes > 0 else {
            throw HelpersError.invalidTagLength
        }
        var bytes = [UInt8](repeating: 0, count: tagLengthBytes)
        let result = SecRandomCopyBytes(kSecRandomDefault, tagLengthBytes, &bytes)
        if result != errSecSuccess {
            throw HelpersError.randomBytesFailed(result)
        }
        return bytes
    }

    /// Fill a given UnsafeMutableRawBufferPointer with secure random bytes
    internal static func generateSecureRandomTag(destination: UnsafeMutableRawBufferPointer) throws {
        guard !destination.isEmpty else {
            throw HelpersError.emptyDestinationBuffer
        }
        let result = SecRandomCopyBytes(kSecRandomDefault, destination.count, destination.baseAddress!)
        if result != errSecSuccess {
            throw HelpersError.randomBytesFailed(result)
        }
    }
    
    private static func swapBytes(in data: inout Data, at i: Int, and j: Int) {
        guard i != j, i >= 0, j >= 0, i < data.count, j < data.count else { return }

        data.swapBytes(at: i, and: j)
    }
}
