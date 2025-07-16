//
//  DeriveFinalKeysTests.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 27.06.2025.
//

import XCTest
@testable import Ecliptix_iOS

final class DeriveFinalKeysTests: XCTestCase {
    
//    func testDeriveFinalKeysSwift() {
//        let akeResult = Data((0..<32).map { UInt8($0) })
//        let transcriptHash = Data((32..<64).map { UInt8($0) })
//
//        let result = OpaqueProtocolService.deriveFinalKeys(akeResult: akeResult, transcriptHash: transcriptHash)
//        switch result {
//        case .success(let (sessionKey, clientMacKey, serverMacKey)):
//            print("Swift - sessionKey: \(sessionKey.map { String(format: "%02x", $0) }.joined())")
//            print("Swift - clientMacKey: \(clientMacKey.map { String(format: "%02x", $0) }.joined())")
//            print("Swift - serverMacKey: \(serverMacKey.map { String(format: "%02x", $0) }.joined())")
//            XCTAssertEqual(sessionKey.count, 32)
//            XCTAssertEqual(clientMacKey.count, 32)
//            XCTAssertEqual(serverMacKey.count, 32)
//        case .failure(let error):
//            XCTFail("Failed with error: \(error)")
//        }
//    }
}
