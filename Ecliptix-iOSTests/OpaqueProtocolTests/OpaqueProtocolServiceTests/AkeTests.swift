//
//  AkeTests.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 29.07.2025.
//

import XCTest
import OpenSSL
@testable import Ecliptix_iOS

final class AkeTests: XCTestCase {
    func testClientAke() throws {
        let group = EC_GROUP_new_by_curve_name(NID_X9_62_prime256v1)!
        defer { EC_GROUP_free(group) }

        let ephPriv = try hexToBignum("f0558d1c60d965d2f4eaf7d2919c564eeb15f64b8b5ef5fb5f1f91da6a56e6ce")
        let statPriv = try hexToBignum("4a82fe23e20d573e98d3470fcf381da7660fb9e35e1b993e6236a682fce1fd6c")

        let ctx = BN_CTX_new()!
        defer { BN_CTX_free(ctx) }

        let ephPub = try ECPointUtils.decodeCompressedPoint(
            hexToData("022572823d1dbce7364f471b86e1720ce89b152ff3f2cb410c8b6008778c81a303"),
            group: group, ctx: ctx).get()

        let statPub = try ECPointUtils.decodeCompressedPoint(
            hexToData("022572823d1dbce7364f471b86e1720ce89b152ff3f2cb410c8b6008778c81a303"),
            group: group, ctx: ctx).get()

        let result = try OpaqueAke.performClientAke(
            ephPrivateKey: ephPriv,
            statPrivateKey: statPriv,
            statSPub: statPub,
            ephSPub: ephPub,
            group: group
        ).get()

        let resultHex = hexString(result)
        print("📦 Swift AKE result: \(resultHex)")
        
        let expectedHex = "038CE51CDC00C1C3F9664E07E3349B14EAF28811C169E1CFF09B4FB9ABD2276F7E02249510F3147D938FC89543A9BE0076DDD8DE8A64D24EA9374E7169EB6C9F788F038CE51CDC00C1C3F9664E07E3349B14EAF28811C169E1CFF09B4FB9ABD2276F7E"
            
        if resultHex.lowercased() == expectedHex.lowercased() {
            print("✅ AKE result matches expected C# output")
        } else {
            print("❌ AKE mismatch")
            print("🔹 Expected: \(expectedHex)")
            print("🔸 Actual:   \(resultHex)")
            XCTFail("AKE output does not match expected C# value")
        }
    }
    
    
    func hexToData(_ hex: String) -> Data {
        var data = Data(capacity: hex.count / 2)
        var tempHex = hex
        if hex.count % 2 != 0 {
            tempHex = "0" + hex
        }
        var index = tempHex.startIndex
        while index < tempHex.endIndex {
            let nextIndex = tempHex.index(index, offsetBy: 2)
            let byteString = tempHex[index..<nextIndex]
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        return data
    }

    func hexToBignum(_ hex: String) throws -> UnsafeMutablePointer<BIGNUM> {
        let data = hexToData(hex)
        return try data.withUnsafeBytes { ptr in
            guard let bn = BN_bin2bn(ptr.bindMemory(to: UInt8.self).baseAddress, Int32(data.count), nil) else {
                throw NSError(domain: "hexToBignum", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert hex to BIGNUM"])
            }
            return bn
        }
    }

    func hexString(_ data: Data) -> String {
        return data.map { String(format: "%02x", $0) }.joined()
    }
}
