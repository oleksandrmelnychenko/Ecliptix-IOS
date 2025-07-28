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
            let dh1 = ECPointUtils.pointMul(group: group, point: ephSPub, scalar: ephPrivateKey, ctx: ctx),
            let dh2 = ECPointUtils.pointMul(group: group, point: statSPub, scalar: ephPrivateKey, ctx: ctx),
            let dh3 = ECPointUtils.pointMul(group: group, point: ephSPub, scalar: statPrivateKey, ctx: ctx)
                
        else {
            return .failure(.pointCompressionFailed("AKE failed during EC_POINT_mul"))
        }
        defer { EC_POINT_free(dh1); EC_POINT_free(dh2); EC_POINT_free(dh3) }
                
        guard
            case let .success(c1) = ECPointUtils.compressPoint(dh1, group: group, ctx: ctx),
            case let .success(c2) = ECPointUtils.compressPoint(dh2, group: group, ctx: ctx),
            case let .success(c3) = ECPointUtils.compressPoint(dh3, group: group, ctx: ctx)
        else {
            return .failure(.pointCompressionFailed("AKE failed during point compression"))
        }

        return .success(c1 + c2 + c3)
    }
}
