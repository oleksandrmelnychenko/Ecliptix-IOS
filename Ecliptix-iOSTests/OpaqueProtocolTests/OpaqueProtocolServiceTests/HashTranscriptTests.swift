//
//  HashTranscript.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 27.06.2025.
//

import XCTest
@testable import Ecliptix_iOS

final class HashTranscriptTests: XCTestCase {
    
    func testHashTranscriptSwift() {
        let phoneNumber = "1234567890"
        let oprfResponse = Data(repeating: 0x01, count: 32)
        let clientStaticPublicKey = Data(repeating: 0x02, count: 33)
        let clientEphemeralPublicKey = Data(repeating: 0x03, count: 33)
        let serverStaticPublicKey = Data(repeating: 0x04, count: 33)
        let serverEphemeralPublicKey = Data(repeating: 0x05, count: 33)

        let hash = OpaqueProtocolService().hashTranscript(
            phoneNumber: phoneNumber,
            oprfResponse: oprfResponse,
            clientStaticPublicKey: clientStaticPublicKey,
            clientEphemeralPublicKey: clientEphemeralPublicKey,
            serverStaticPublicKey: serverStaticPublicKey,
            serverEphemeralPublicKey: serverEphemeralPublicKey
        )

        print("Swift - hashTranscript: \(hash.map { String(format: "%02x", $0) }.joined())")
    }

}
