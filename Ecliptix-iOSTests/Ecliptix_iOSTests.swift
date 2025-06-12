//
//  Ecliptix_iOSTests.swift
//  Ecliptix-iOSTests
//
//  Created by Oleksandr Melnechenko on 12.06.2025.
//

import XCTest
@testable import Ecliptix_iOS

final class Ecliptix_iOSTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // Setup identities and create two sessions (Alice and Bob)
        let aliceMaterialResult = EcliptixSystemIdentityKeys.create(oneTimeKeyCount: 1)
        guard aliceMaterialResult.isOk else {
            XCTFail("Failed to create Alice keys")
            return
        }
        let aliceMaterial = try aliceMaterialResult.unwrap()
        
        let bobMaterialResult = EcliptixSystemIdentityKeys.create(oneTimeKeyCount: 2)
        guard bobMaterialResult.isOk else {
            XCTFail("Failed to create Bob keys")
            return
        }
        let bobMaterial = try bobMaterialResult.unwrap()
        
        let aliceSystem = EcliptixProtocolSystem(ecliptixSystemIdentityKeys: aliceMaterial)
        let bobSystem = EcliptixProtocolSystem(ecliptixSystemIdentityKeys: bobMaterial)
    
        let connectId: UInt32 = 2
        let exchangeType = Ecliptix_Proto_PubKeyExchangeType.dataCenterEphemeralConnect
        
        // Alice initiates exchange
        let aliceInitialMsg = try aliceSystem.beginDataCenterPubKeyExchange(
            connectId: connectId,
            exchangeType: exchangeType
        )
        let bobResponseMsg = try bobSystem.processAndRespondToPubKeyExchange(
            connectId: connectId,
            peerInitialMessageProto: aliceInitialMsg
        )
        try aliceSystem.completeDataCenterPubKeyExchange(
            connectId: connectId,
            exchangeType: exchangeType,
            peerMessage: bobResponseMsg
        )
        
        var ratchetTriggered = false
        
        for i in 1...10 {
            let msgData = "Msg \(i)".data(using: .utf8)!
            let cipher = try aliceSystem.produceOutboundMessage(
                connectId: connectId,
                exchangeType: exchangeType,
                plainPayload: msgData)
            
            if !cipher.dhPublicKey.isEmpty {
                ratchetTriggered = true
                print("Ratchet triggered at message \(i)")
            }
            
            _ = try bobSystem.processInboundMessage(
                sessionId: connectId,
                exchangeType: exchangeType,
                cipherPayloadProto: cipher)
        }
        
        XCTAssertTrue(ratchetTriggered, "DH ratchet did not trigger at interval 10.")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
