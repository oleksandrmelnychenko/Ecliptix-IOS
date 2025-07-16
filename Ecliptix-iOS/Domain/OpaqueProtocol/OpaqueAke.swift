//
//  OpaqueAke.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 01.07.2025.
//

import OpenSSL
import Foundation

enum OpaqueAke {
    static func performClientAke(
        ephPrivateKey: UnsafePointer<BIGNUM>,
        statPrivateKey: UnsafePointer<BIGNUM>,
        statSPub: OpaquePointer,
        ephSPub: OpaquePointer,
        group: OpaquePointer
    ) -> Result<Data, OpaqueFailure> {
        let ctx = BN_CTX_new()!
        defer { BN_CTX_free(ctx) }

        guard
            let dh1 = pointMul(group: group, point: ephSPub, scalar: ephPrivateKey, ctx: ctx),
            let dh2 = pointMul(group: group, point: statSPub, scalar: ephPrivateKey, ctx: ctx),
            let dh3 = pointMul(group: group, point: ephSPub, scalar: statPrivateKey, ctx: ctx)
                
        else {
            return .failure(.pointCompressionFailed("AKE failed during EC_POINT_mul"))
        }
        defer { EC_POINT_free(dh1); EC_POINT_free(dh2); EC_POINT_free(dh3) }

        print("statPrivateKey is zero:", BN_is_zero(statPrivateKey) == 1)
        print("ephSPub is on curve:", EC_POINT_is_on_curve(group, ephSPub, ctx) == 1)
        print("ephSPub is at infinity:", EC_POINT_is_at_infinity(group, ephSPub) == 1)

        
        print("dh3:", describePoint(dh3, group: group, ctx: ctx))
        
        guard
            let c1 = compressPoint(dh1, group: group, ctx: ctx),
            let c2 = compressPoint(dh2, group: group, ctx: ctx),
            let c3 = compressPoint(dh3, group: group, ctx: ctx)
        else {
            return .failure(.pointCompressionFailed("AKE failed during point compression"))
        }

        return .success(c1 + c2 + c3)
    }
    
    private static func pointMul(
        group: OpaquePointer,
        point: OpaquePointer,
        scalar: UnsafePointer<BIGNUM>,
        ctx: OpaquePointer
    ) -> OpaquePointer? {
        let result = EC_POINT_new(group)
        guard EC_POINT_mul(group, result, nil, point, scalar, ctx) == 1 else {
            EC_POINT_free(result)
            return nil
        }
        return result
    }
    
    private static func compressPoint(
        _ point: OpaquePointer,
        group: OpaquePointer,
        ctx: OpaquePointer
    ) -> Data? {
        var buf = Data(repeating: 0, count: 33)
        let count = buf.count

        let success = buf.withUnsafeMutableBytes {
            EC_POINT_point2oct(group, point, POINT_CONVERSION_COMPRESSED, $0.baseAddress?.assumingMemoryBound(to: UInt8.self), count, ctx)
        }
        
        return success > 0 ? buf : nil
    }
    
    private static func describePoint(_ point: OpaquePointer, group: OpaquePointer, ctx: OpaquePointer) -> String {
        var buffer = [UInt8](repeating: 0, count: 65)
        let len = EC_POINT_point2oct(group, point, POINT_CONVERSION_UNCOMPRESSED, &buffer, buffer.count, ctx)
        return len > 0 ? Data(buffer[..<len]).map { String(format: "%02x", $0) }.joined() : "<invalid>"
    }


}
