//
//  Ecliptix_iOSTests.swift
//  Ecliptix-iOSTests
//
//  Created by Oleksandr Melnechenko on 12.06.2025.
//

import XCTest
@testable import Ecliptix_iOS

final class Ecliptix_iOSTests: XCTestCase {

//    func testExample() throws {
//        // Setup identities and create two sessions (Alice and Bob)
//        let aliceMaterialResult = EcliptixSystemIdentityKeys.create(oneTimeKeyCount: 1)
//        guard aliceMaterialResult.isOk else {
//            XCTFail("Failed to create Alice keys")
//            return
//        }
//        let aliceMaterial = try aliceMaterialResult.unwrap()
//        
//        let bobMaterialResult = EcliptixSystemIdentityKeys.create(oneTimeKeyCount: 2)
//        guard bobMaterialResult.isOk else {
//            XCTFail("Failed to create Bob keys")
//            return
//        }
//        let bobMaterial = try bobMaterialResult.unwrap()
//        
//        let aliceSystem = EcliptixProtocolSystem(ecliptixSystemIdentityKeys: aliceMaterial)
//        let bobSystem = EcliptixProtocolSystem(ecliptixSystemIdentityKeys: bobMaterial)
//    
//        let connectId: UInt32 = 2
//        let exchangeType = Ecliptix_Proto_PubKeyExchangeType.dataCenterEphemeralConnect
//        
//        // Alice initiates exchange
//        let aliceInitialMsgResult = try aliceSystem.beginDataCenterPubKeyExchange(
//            connectId: connectId,
//            exchangeType: exchangeType
//        )
//        if aliceInitialMsgResult.isErr {
//            XCTFail("Failed to create Alice initial message")
//            return
//        }
//        var aliceInitialMsg = try aliceInitialMsgResult.unwrap()
//        
//        let bobResponseMsgResult = try bobSystem.processAndRespondToPubKeyExchange(
//            connectId: connectId,
//            peerInitialMessageProto: &aliceInitialMsg
//        )
//        if bobResponseMsgResult.isErr {
//            XCTFail("Failed to process Bob response message")
//            return
//        }
//        var bobResponseMsg = try bobResponseMsgResult.unwrap()
//        
//        let completeDataCenterPubKeyExchangeResult = try aliceSystem.completeDataCenterPubKeyExchange(exchangeType: exchangeType, peerMessage: &bobResponseMsg)
//        if completeDataCenterPubKeyExchangeResult.isErr {
//            XCTFail("Failed to complete data center pub key exchange")
//            return
//        }
//        
//        var ratchetTriggered = false
//        
//        for i in 1...10 {
//            let msgData = "Msg \(i)".data(using: .utf8)!
//            let cipherResult = try aliceSystem.produceOutboundMessage(
//                plainPayload: msgData)
//            
//            if cipherResult.isErr {
//                XCTFail("Failed to produce ciphertext for message \(i)")
//                return
//            }
//            let cipher = try cipherResult.unwrap()
//            
//            if !cipher.dhPublicKey.isEmpty {
//                ratchetTriggered = true
//                print("Ratchet triggered at message \(i)")
//            }
//            
//            let processInboundMessageResult = try bobSystem.processInboundMessage(
//                cipherPayloadProto: cipher)
//            
//            if processInboundMessageResult.isErr {
//                XCTFail("Failed to process inbound message \(i)")
//                return
//            }
//        }
//        
//        XCTAssertTrue(ratchetTriggered, "DH ratchet did not trigger at interval 10.")
//    }
//
//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
