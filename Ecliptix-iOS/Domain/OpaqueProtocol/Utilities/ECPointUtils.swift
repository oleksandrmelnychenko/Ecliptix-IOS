//
//  ECPointUtils.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 28.07.2025.
//

import Foundation
import OpenSSL

struct ECPointUtils {
    static func generateRandomScalar(group: OpaquePointer) -> UnsafeMutablePointer<BIGNUM>? {
        let group = group
        let ctx = BN_CTX_new()
        guard ctx != nil else { return nil }
        defer { BN_CTX_free(ctx) }
        
        let order = BN_new()
        guard order != nil else { return nil }
        defer { BN_free(order) }
        
        guard EC_GROUP_get_order(group, order, ctx) == 1 else { return nil }
        
        let scalar = BN_new()
        guard scalar != nil else { return nil }
        
        repeat {
            if BN_rand_range(scalar, order) != 1 {
                BN_free(scalar)
                return nil
            }
        } while BN_is_zero(scalar) == 1
        
        return scalar
    }
    
    static func generateKeyPair(group: OpaquePointer) -> (privateKey: UnsafeMutablePointer<BIGNUM>, publicKey: OpaquePointer)? {
        let group = group
        let ctx = BN_CTX_new()
        guard ctx != nil else { return nil }
        defer { BN_CTX_free(ctx) }
        
        let order = BN_new()
        guard order != nil else { return nil }
        defer { BN_free(order) }
        
        guard EC_GROUP_get_order(group, order, ctx) == 1 else { return nil }
        
        let privateKey = BN_new()
        guard privateKey != nil else { return nil }
        
        repeat {
            if BN_rand_range(privateKey, order) != 1 {
                BN_free(privateKey)
                return nil
            }
        } while BN_is_zero(privateKey) == 1
        
        guard let publicKey = EC_POINT_new(group) else {
            BN_free(privateKey)
            return nil
        }
        
        guard EC_POINT_mul(group, publicKey, privateKey, nil, nil, ctx) == 1 else {
            EC_POINT_free(publicKey)
            BN_free(privateKey)
            return nil
        }
        
        return (privateKey: privateKey!, publicKey: publicKey)
    }
    
    static func decodeCompressedPoint(_ data: Data, group: OpaquePointer, ctx: OpaquePointer) -> Result<OpaquePointer, OpaqueFailure> {
        guard let point = EC_POINT_new(group) else {
            return .failure(.pointDecodingFailed("Failed to create EC_POINT"))
        }
        
        let success = data.withUnsafeBytes {
            EC_POINT_oct2point(group, point,
                               $0.baseAddress!.assumingMemoryBound(to: UInt8.self),
                               data.count, ctx) == 1
        }
        
        guard success else {
            EC_POINT_free(point)
            return .failure(.pointDecodingFailed("Failed to decode EC point from data"))
        }
        
        return .success(point)
    }
    
    static func compressPoint(
        _ point: OpaquePointer,
        group: OpaquePointer,
        ctx: OpaquePointer
    ) -> Result<Data, OpaqueFailure> {
        var compressed = Data(repeating: 0, count: OpaqueConstants.ecCompressedPointLength)
        
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
    ) -> OpaquePointer? {
        let result = EC_POINT_new(group)
        guard EC_POINT_mul(group, result, nil, point, scalar, ctx) == 1 else {
            EC_POINT_free(result)
            return nil
        }
        return result
    }
}
