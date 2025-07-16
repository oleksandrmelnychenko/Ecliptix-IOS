//
//  RecoverOprfKeyTests.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 27.06.2025.
//

import XCTest
import OpenSSL
@testable import Ecliptix_iOS

final class RecoverOprfKeyTests: XCTestCase {
    
//    func testRecoverOprfKeyMatchesCSharp() throws {
//        let group = EC_GROUP_new_by_curve_name(NID_X9_62_prime256v1)!
//        defer { EC_GROUP_free(group) }
//
//        let ctx = BN_CTX_new()!
//        defer { BN_CTX_free(ctx) }
//
//        // Точка (наприклад, результат OPRF)
//        let oprfPointHex = "02a1633cafb7adfb3912c3edfb1e5cf55f83b6b5315983a3b6df9e8c775e1c6a8b"
//        let oprfData = Data(hex: oprfPointHex)
//
//        var blindPtr: UnsafeMutablePointer<BIGNUM>? = BN_new()
//        _ = "6F8F57715090DA2632453988D9A1501B".withCString {
//            BN_hex2bn(&blindPtr, $0)
//        }
//
//        let swiftResult = try XCTUnwrap(
//            OpaqueProtocolService.recoverOprfKey(oprfResponse: oprfData, blind: blindPtr!.pointee, group: group).get()
//        )
//
//        print("Swift recovered key: \(swiftResult.map { String(format:"%02x", $0) }.joined())")
//
//        let csharpHex = "037c647eaedd9ea564937ef0d15df00af5ab4a14886bd210ab4ed96104b73cacfd" // отримати з C#
//        let csharpResult = Data(hex: csharpHex)
//
//        XCTAssertEqual(swiftResult, csharpResult)
//    }

}
