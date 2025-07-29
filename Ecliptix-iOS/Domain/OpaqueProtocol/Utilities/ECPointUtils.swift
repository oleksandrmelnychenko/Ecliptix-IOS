//
//  ECPointUtils.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 28.07.2025.
//

import Foundation
import OpenSSL

struct ECPointUtils {
    static func generateRandomScalar(
        group: OpaquePointer
    ) -> Result<UnsafeMutablePointer<BIGNUM>, OpaqueFailure> {
        return withBnCtx { ctx in
            Self.getOrder(of: group, ctx: ctx)
                .flatMap { order in
                    defer { BN_free(order) }

                    return Self.randomNonZeroBignum(lessThan: order)
                }
        }
    }
    
    static func generateKeyPair(
        group: OpaquePointer
    ) -> Result<(privateKey: UnsafeMutablePointer<BIGNUM>, publicKey: OpaquePointer), OpaqueFailure> {
        return withBnCtx { ctx in
            Self.getOrder(of: group, ctx: ctx)
                .flatMap { order in
                    defer { BN_free(order) }

                    return Self.randomNonZeroBignum(lessThan: order)
                        .flatMap { privateKey in
                            Self.newEcPoint(group: group)
                                .flatMap { publicKey in
                                    guard EC_POINT_mul(group, publicKey, privateKey, nil, nil, ctx) == 1 else {
                                        EC_POINT_free(publicKey)
                                        BN_free(privateKey)
                                        return .failure(.pointMultiplicationFailed("Failed to generate public key from private key"))
                                    }

                                    return .success((privateKey, publicKey))
                                }
                        }
                }
        }
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
    
    static func getOrder(of group: OpaquePointer, ctx: OpaquePointer) -> Result<UnsafeMutablePointer<BIGNUM>, OpaqueFailure> {
        return withBn { bn in
            guard EC_GROUP_get_order(group, bn, ctx) == 1 else {
                return .failure(.invalidInput("Failed to get group order"))
            }

            return .success(bn)
        }
    }
    
    static func randomNonZeroBignum(
        lessThan upperBound: UnsafePointer<BIGNUM>
    ) -> Result<UnsafeMutablePointer<BIGNUM>, OpaqueFailure> {
        return withBn { bn in
            var success = false
            repeat {
                success = BN_rand_range(bn, upperBound) == 1
                if !success {
                    return .failure(.invalidInput("Failed to generate random BIGNUM"))
                }
            } while BN_is_zero(bn) == 1

            return .success(bn)
        }
    }
    
    static func newEcPoint(group: OpaquePointer) -> Result<OpaquePointer, OpaqueFailure> {
        guard let point = EC_POINT_new(group) else {
            return .failure(.pointMultiplicationFailed("Failed to allocate EC_POINT"))
        }
        return .success(point)
    }
    
    
    @discardableResult
    static func withBnCtx<ResultType>(
        _ body: (OpaquePointer) -> Result<ResultType, OpaqueFailure>
    ) -> Result<ResultType, OpaqueFailure> {
        guard let ctx = BN_CTX_new() else {
            return .failure(.invalidInput("Failed to create BN_CTX"))
        }
        defer { BN_CTX_free(ctx) }
        return body(ctx)
    }
    
    @discardableResult
    static func withBn<ResultType>(
        _ body: (UnsafeMutablePointer<BIGNUM>) -> Result<ResultType, OpaqueFailure>
    ) -> Result<ResultType, OpaqueFailure> {
        guard let bn = BN_new() else {
            return .failure(.invalidInput("Failed to allocate BIGNUM"))
        }
        let result = body(bn)
        
        if case .failure = result {
            BN_free(bn)
        }
        return result
    }
}
