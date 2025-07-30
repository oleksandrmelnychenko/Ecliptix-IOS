//
//  OpaqueCryptoUtilities.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 26.06.2025.
//

import Foundation
import OpenSSL

struct OpaqueHashingUtils {
    static func recoverOprfKey(oprfResponse: Data, blind: UnsafePointer<BIGNUM>, group: OpaquePointer) -> Result<Data, OpaqueFailure> {
        return ECPointUtils.withBnCtx { ctx in
            ECPointUtils.decodeCompressedPoint(oprfResponse, group: group, ctx: ctx)
                .flatMap { point in
                    defer { EC_POINT_free(point) }

                    return BigNumUtils.getOrder(of: group, ctx: ctx)
                        .flatMap { order in
                            defer { BN_free(order) }

                            return BigNumUtils.invertScalar(blind, mod: order, ctx: ctx)
                                .flatMap { blindInv in
                                    defer { BN_free(blindInv) }

                                    return ECPublicKeyUtils.pointMul(group: group, point: point, scalar: blindInv, ctx: ctx)
                                        .flatMap { finalPoint in
                                            defer { EC_POINT_free(finalPoint) }
                                            
                                            return ECPublicKeyUtils.compressPoint(finalPoint, group: group, ctx: ctx)
                                        }
                                }
                        }
                }
        }
    }

    static func hashToPoint(_ input: Data, group: OpaquePointer) -> Result<Data, OpaqueFailure> {
        return EVPCryptoUtils.withEvpCtx { ctx in
            ECPointUtils.withBnCtx { bnCtx in
                let attempts: Int = 255
                var counter: UInt8 = 0

                while counter < attempts {
                    let hashResult = hashInputWithCounter(input: input, counter: counter, ctx: ctx)
                    
                    switch hashResult {
                    case .failure:
                        counter &+= 1
                        continue

                    case .success(let hash):
                        let compressed = createCompressedPointCandidate(from: hash)
                        let decodeResult = tryDecodeValidPoint(from: compressed, group: group, ctx: bnCtx)

                        if case let .success(point) = decodeResult {
                            defer { EC_POINT_free(point) }
                            return ECPublicKeyUtils.compressPoint(point, group: group, ctx: bnCtx)
                        }
                    }

                    counter &+= 1
                    
                }

                return .failure(.hashToPointFailed("Failed to find valid EC point in \(attempts) attempts"))
            }
        }
    }
    
    private static func hashInputWithCounter(
        input: Data,
        counter: UInt8,
        ctx: OpaquePointer
    ) -> Result<[UInt8], OpaqueFailure> {
        let counterData = withUnsafeBytes(of: counter) { Data($0) }

        return EVPCryptoUtils.evpHash(ctx: ctx, inputs: [input, counterData])
            .map { Array($0) }
    }

    
    private static func createCompressedPointCandidate(from hash: [UInt8]) -> Data {
        let prefix = [OpaqueConstants.ecCompressedPrefixEven]
        let body = hash.prefix(OpaqueConstants.defaultKeyLength)
        return Data(prefix + body)
    }
    
    private static func tryDecodeValidPoint(
        from compressed: Data,
        group: OpaquePointer,
        ctx: OpaquePointer
    ) -> Result<OpaquePointer, OpaqueFailure> {
        return ECPointUtils.decodeCompressedPoint(compressed, group: group, ctx: ctx)
            .flatMap { point in
                if EC_POINT_is_on_curve(group, point, ctx) == 1 {
                    return .success(point)
                } else {
                    EC_POINT_free(point)
                    return .failure(.pointNotOnCurve("Point not on curve"))
                }
            }
    }
}
