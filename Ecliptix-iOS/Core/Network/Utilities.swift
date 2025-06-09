//
//  Utilities.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import Foundation
import SwiftProtobuf
import CryptoKit

public class Utilities {
    private let invalidPayloadDataLengthMessage = "Invalid payload data length."
    private static let fullUInt32Range = UInt32.min...UInt32.max
    
    public func guidToByteArray(_ uuid: UUID) -> Data {
        let byteArray = withUnsafeBytes(of: uuid.uuid) { Data($0) }
        var bytes = byteArray
        bytes.replaceSubrange(0..<4, with: bytes[0..<4].reversed())
        bytes.replaceSubrange(4..<6, with: bytes[4..<6].reversed())
        bytes.replaceSubrange(6..<8, with: bytes[6..<8].reversed())
        return bytes
    }
    
    public func readMemoryToRetrieveBytes(_ data: Data) throws -> Data {
        guard !data.isEmpty else {
            throw HelpersError.invalidPayloadDataLength
        }
        return data
    }
    
    public func fromByteStringToGuid(_ byteString: Data) throws -> UUID {
        var bytes = Data(byteString)

        guard bytes.count == 16 else {
            throw HelpersError.invalidPayloadDataLength
        }

        bytes[0..<4].reverse()
        bytes[4..<6].reverse()
        bytes[6..<8].reverse()

        let uuid = bytes.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> UUID in
            let rawPtr = ptr.baseAddress!
            return UUID(uuid: rawPtr.load(as: uuid_t.self))
        }

        return uuid
    }
    
    public static func generateRandomUInt32(in range: ClosedRange<UInt32>) -> UInt32 {
        return UInt32.random(in: range)
    }
    
    public static func generateRandomUInt32() -> UInt32 {
        return UInt32.random(in: fullUInt32Range)
    }
    
    public static func extractCipherPayload(from requestedEncryptedPayload: Data, connectionId: String, decryptPayloadFun: @escaping (_ data: Data, _ connectionId: String, _ flag: Int) async throws -> Data) async throws -> Data {
        
        let encryptedPayload = Data(requestedEncryptedPayload)
        return try await decryptPayloadFun(encryptedPayload, connectionId, 0)
    }
    
    public static func parseFromBytes<T: SwiftProtobuf.Message>(_ type: T.Type, data: Data) throws -> T {
        do {
            return try T(serializedBytes: [UInt8](data))
        } catch {
            throw HelpersError.protobufParsingFailed(error.localizedDescription)
        }
    }
    
    public static func computeUniqueConnectId(appInstanceId: UUID, appDeviceId: UUID, contextType: Ecliptix_Proto_PubKeyExchangeType, operationContextId: UUID?) -> UInt32 {
        var combined = Data()
        withUnsafeBytes(of: appInstanceId.uuid) { combined.append(contentsOf: $0) }
        withUnsafeBytes(of: appDeviceId.uuid) { combined.append(contentsOf: $0) }
        
        // Add contextType as big-endian UInt32
        var contextTypeValue = UInt32(contextType.rawValue).bigEndian
        withUnsafeBytes(of: &contextTypeValue) { combined.append(contentsOf: $0) }

        // Add operationContextId if present
        if let opContextId = operationContextId {
            withUnsafeBytes(of: opContextId.uuid) { combined.append(contentsOf: $0) }
        }

        let hash = SHA256.hash(data: combined)

        let first4Bytes = Array(hash.prefix(4))
        return first4Bytes.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
    }
}
