//
//  Utilities.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import Foundation
import SwiftProtobuf
import CryptoKit

internal class Utilities {
    private let invalidPayloadDataLengthMessage = "Invalid payload data length."
    private static let fullUInt32Range = UInt32.min...UInt32.max
    
    public static func readMemoryToRetrieveBytes(_ data: Data) throws -> Data {
        guard !data.isEmpty else {
            throw HelpersError.invalidPayloadDataLength
        }
        return data
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
        
        var mutableData = data

        mutableData.swapBytes(at: 0, and: 3)
        mutableData.swapBytes(at: 1, and: 2)
        mutableData.swapBytes(at: 4, and: 5)
        mutableData.swapBytes(at: 6, and: 7)

        return mutableData.withUnsafeBytes { buffer -> UUID in
            let uuid = buffer.bindMemory(to: uuid_t.self)
            return UUID(uuid: uuid[0])
        }
    }
    
    public static func generateRandomUInt32(in range: ClosedRange<UInt32>) -> UInt32 {
        return UInt32.random(in: range)
    }
    
    public static func generateRandomUInt32() -> UInt32 {
        return Self.generateRandomUInt32(in: fullUInt32Range)
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
    
    private static func swapBytes(in data: inout Data, at i: Int, and j: Int) {
        guard i != j, i >= 0, j >= 0, i < data.count, j < data.count else { return }

        data.swapBytes(at: i, and: j)
    }
}
