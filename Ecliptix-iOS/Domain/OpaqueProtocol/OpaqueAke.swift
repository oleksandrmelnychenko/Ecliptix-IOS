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
        return ECPointUtils.withBnCtx { ctx in
            ECPublicKeyUtils.pointMul(group: group, point: ephSPub, scalar: ephPrivateKey, ctx: ctx)
                .flatMap { dh1 in
                    ECPublicKeyUtils.pointMul(group: group, point: statSPub, scalar: ephPrivateKey, ctx: ctx)
                        .flatMap { dh2 in
                            ECPublicKeyUtils.pointMul(group: group, point: ephSPub, scalar: statPrivateKey, ctx: ctx)
                                .flatMap { dh3 in

                                    defer {
                                        EC_POINT_free(dh1)
                                        EC_POINT_free(dh2)
                                        EC_POINT_free(dh3)
                                    }
                                    
                                    return ECPublicKeyUtils.compressPoint(dh1, group: group, ctx: ctx)
                                        .flatMap { c1 in
                                            ECPublicKeyUtils.compressPoint(dh2, group: group, ctx: ctx)
                                                .flatMap { c2 in
                                                    ECPublicKeyUtils.compressPoint(dh3, group: group, ctx: ctx)
                                                        .map { c3 in
                                                            return c1 + c2 + c3
                                                        }
                                                }
                                        }
                                }
                        }
                }
        }
    }
}
