//
//  PerformClientAkeTests.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 27.06.2025.
//

import XCTest
import OpenSSL
@testable import Ecliptix_iOS

final class PerformClientAkeTests: XCTestCase {
    
//    func testPerformClientAkeMatchesCSharp() throws {
//        // Підготовка групи та контексту
//        let group = EC_GROUP_new_by_curve_name(NID_X9_62_prime256v1)!
//        defer { EC_GROUP_free(group) }
//
//        let ctx = BN_CTX_new()!
//        defer { BN_CTX_free(ctx) }
//
//        var ephPrivPtr: UnsafeMutablePointer<BIGNUM>? = BN_new()
//        _ = "ad07dfd8298e193e16659b13b6259b7be8c8fd00704e4ee5a443d3de5a1bebd2".withCString {
//            BN_hex2bn(&ephPrivPtr, $0)
//        }
//        let ephPriv = ephPrivPtr!
//
//        var statPrivPtr: UnsafeMutablePointer<BIGNUM>? = BN_new()
//        _ = "628d2b797f01ce5bee5d0d5ca79c3389272e42faa12613cfe5e5492d36d647a6".withCString {
//            BN_hex2bn(&statPrivPtr, $0)
//        }
//        let statPriv = statPrivPtr!
//
//
//        let statSPub = EC_POINT_hex2point(group, "0372f1e130277b0038bdf64cd4fdb66f5de3f0aa63d86071e0a40ff971b873741a", nil, ctx)
//        let ephSPub = EC_POINT_hex2point(group, "025f4d82a78facce8c3d284afa61bdbb3c57fe146ff3076dd22fba0285f1e6173e", nil, ctx)
//
//        let swiftResult = try XCTUnwrap(
//            OpaqueProtocolService.performClientAke(
//                ephPrivateKey: ephPriv,
//                statPrivateKey: statPriv,
//                statSPub: statSPub!,
//                ephSPub: ephSPub!,
//                group: group
//            ).get()
//        )
//
//        print("Swift AKE: \(swiftResult.map { String(format:"%02x", $0) }.joined())")
//
//        let csharpHex = "021289f814d3d9e41a5651af78493d43cc44c62160d1c583413659a555bac3780d02b9def903e23e45b4f7d6ff7d19ffd090cd09b95d58af09b5877cee4688f2f56a0384304f39c51bb5df835f767f3e2d8e61a435e98141b0ea014b49029869aa6e12" // вставити з C# (hex рядок)
//        let csharpData = Data(hex: csharpHex)
//
//        XCTAssertEqual(swiftResult, csharpData)
//    }



}
