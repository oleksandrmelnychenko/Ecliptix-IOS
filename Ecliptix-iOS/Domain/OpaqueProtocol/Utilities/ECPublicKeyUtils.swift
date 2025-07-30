//
//  ECPublicKeyUtils.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.07.2025.
//

import Foundation
import OpenSSL

enum ECPublicKeyUtils {
    static func compressPoint(
        _ point: OpaquePointer,
        group: OpaquePointer,
        ctx: OpaquePointer
    ) -> Result<Data, OpaqueFailure> {
        var compressed = Data(repeating: 0, count: OpaqueConstants.ecCompressedPointLength)
        
        if EC_POINT_is_on_curve(group, point, ctx) != 1 {
            return .failure(.pointCompressionFailed("Point is not on curve"))
        }
        
        if EC_POINT_is_at_infinity(group, point) == 1 {
            return .failure(.pointCompressionFailed("Point is at infinity"))
        }
        
        let written = compressed.withUnsafeMutableBytes {
            EC_POINT_point2oct(
                group,
                point,
                POINT_CONVERSION_COMPRESSED,
                $0.baseAddress?.assumingMemoryBound(to: UInt8.self),
                OpaqueConstants.ecCompressedPointLength,
                ctx
            )
        }
        
        guard written == OpaqueConstants.ecCompressedPointLength else {
            return .failure(.pointCompressionFailed("Invalid compressed point length"))
        }
        
        return .success(compressed)
    }
    
    static func decodeCompressedPoint(_ data: Data, group: OpaquePointer, ctx: OpaquePointer) -> Result<OpaquePointer, OpaqueFailure> {
        return Self.newEcPoint(group: group)
            .flatMap { point in
                let success = data.withUnsafeBytes { rawBuffer -> Bool in
                    guard let base = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                        return false
                    }
                    return EC_POINT_oct2point(group, point, base, data.count, ctx) == 1
                }

                guard success else {
                    EC_POINT_free(point)
                    return .failure(.pointDecodingFailed("Failed to decode EC point from data"))
                }

                return .success(point)
            }
    }
    
    
    static func newEcPoint(group: OpaquePointer) -> Result<OpaquePointer, OpaqueFailure> {
        guard let point = EC_POINT_new(group) else {
            return .failure(.pointMultiplicationFailed("Failed to allocate EC_POINT"))
        }
        return .success(point)
    }
    
    static func pointMul(
        group: OpaquePointer,
        point: OpaquePointer,
        scalar: UnsafePointer<BIGNUM>,
        ctx: OpaquePointer
    ) -> Result<OpaquePointer, OpaqueFailure> {
        return Self.newEcPoint(group: group)
            .flatMap { resultPoint in
                guard EC_POINT_mul(group, resultPoint, nil, point, scalar, ctx) == 1 else {
                    EC_POINT_free(resultPoint)
                    return .failure(.pointMultiplicationFailed("EC_POINT_mul failed"))
                }

                return .success(resultPoint)
            }
    }
}
