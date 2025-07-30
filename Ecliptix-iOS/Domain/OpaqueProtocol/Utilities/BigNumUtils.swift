//
//  BigNumUtils.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.07.2025.
//

import Foundation
import OpenSSL

enum BigNumUtils {
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
    
    static func generateRandomScalar(
        group: OpaquePointer
    ) -> Result<UnsafeMutablePointer<BIGNUM>, OpaqueFailure> {
        return ECPointUtils.withBnCtx { ctx in
            BigNumUtils.getOrder(of: group, ctx: ctx)
                .flatMap { order in
                    defer { BN_free(order) }

                    return BigNumUtils.randomNonZeroBignum(lessThan: order)
                }
        }
    }
    
    static func invertScalar(
        _ scalar: UnsafePointer<BIGNUM>,
        mod modulus: UnsafePointer<BIGNUM>,
        ctx: OpaquePointer
    ) -> Result<UnsafeMutablePointer<BIGNUM>, OpaqueFailure> {
        
        guard let inverse = BN_mod_inverse(nil, scalar, modulus, ctx) else {
            return .failure(.invalidInput("Failed to compute modular inverse"))
        }

        return .success(inverse)
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
    
    static func getOrder(of group: OpaquePointer, ctx: OpaquePointer) -> Result<UnsafeMutablePointer<BIGNUM>, OpaqueFailure> {
        return withBn { bn in
            guard EC_GROUP_get_order(group, bn, ctx) == 1 else {
                return .failure(.invalidInput("Failed to get group order"))
            }

            return .success(bn)
        }
    }
}
