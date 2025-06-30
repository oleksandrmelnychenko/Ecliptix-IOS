//
//  hashToPointTests.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 27.06.2025.
//

import XCTest
import BigInt
@testable import Ecliptix_iOS

final class HashToPointTests: XCTestCase {
    
    func testHashToPointSwift() {
        let input = "password123".data(using: .utf8)!
        let result = OpaqueCryptoUtilities.hashToPoint(input)
        
        switch result {
        case .success(let oprfRequest):
            print("Swift - oprfRequest: \(oprfRequest.map { String(format: "%02x", $0) }.joined())")
            XCTAssertEqual(oprfRequest.count, 33)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }
}
