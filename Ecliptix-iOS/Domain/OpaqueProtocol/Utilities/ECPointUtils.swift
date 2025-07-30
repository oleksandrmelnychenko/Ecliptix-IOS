//
//  ECPointUtils.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 28.07.2025.
//

import Foundation
import OpenSSL

struct ECPointUtils {
    static func generateKeyPair(
        group: OpaquePointer
    ) -> Result<EcKeyPair, OpaqueFailure> {
        return withBnCtx { ctx in
            BigNumUtils.getOrder(of: group, ctx: ctx)
                .flatMap { order in
                    defer { BN_free(order) }

                    return BigNumUtils.randomNonZeroBignum(lessThan: order)
                        .flatMap { privateKey in
                            ECPublicKeyUtils.newEcPoint(group: group)
                                .flatMap { publicKey in
                                    guard EC_POINT_mul(group, publicKey, privateKey, nil, nil, ctx) == 1 else {
                                        EC_POINT_free(publicKey)
                                        BN_free(privateKey)
                                        return .failure(.pointMultiplicationFailed("Failed to generate public key from private key"))
                                    }

                                    return .success(EcKeyPair(privateKey: privateKey, publicKey: publicKey))
                                }
                        }
                }
        }
    }

    static func decodeCompressedPoint(_ data: Data, group: OpaquePointer, ctx: OpaquePointer) -> Result<OpaquePointer, OpaqueFailure> {
        return ECPublicKeyUtils.newEcPoint(group: group)
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
}
