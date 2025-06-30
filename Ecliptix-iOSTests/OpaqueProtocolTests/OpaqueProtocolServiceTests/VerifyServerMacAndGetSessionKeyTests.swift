//
//  VerifyServerMacAndGetSessionKeyTests.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 27.06.2025.
//

import XCTest
@testable import Ecliptix_iOS

final class VerifyServerMacAndGetSessionKeyTests: XCTestCase {
    
    func testVerifyServerMacAndGetSessionKeyMatchesCSharp() throws {
        let sessionKey = Data(hex: "843805d9f186845d5b01b97c51ccfae0b36562ad6ce0feaf6b1701e92f3debf2")
        let serverMacKey = Data(hex: "6a33632343ec99fdd1e0d53b47a46b1329735e42f7a49fc942188f6b9478a6df")
        let transcriptHash = Data(hex: "e0efdd8f69dbd91f61ff1b1706df7285526ae521c46d03d04d11b385fae79a93")

        let expectedMac = OpaqueProtocolService.createMac(key: serverMacKey, data: transcriptHash)

        var response = Ecliptix_Proto_Membership_OpaqueSignInFinalizeResponse()
        response.serverMac = expectedMac

        let result = OpaqueProtocolService().verifyServerMacAndGetSessionKey(
            response: response,
            sessionKey: sessionKey,
            serverMacKey: serverMacKey,
            transcriptHash: transcriptHash
        )

        switch result {
        case .success(let key):
            XCTAssertEqual(key, sessionKey)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }
}
