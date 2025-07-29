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
        guard let ctx = BN_CTX_new() else {
            return .failure(.invalidInput("Failed to create BN_CTX"))
        }
        defer { BN_CTX_free(ctx) }

        return ECPointUtils.pointMul(group: group, point: ephSPub, scalar: ephPrivateKey, ctx: ctx)
            .flatMap { dh1 in
                ECPointUtils.pointMul(group: group, point: statSPub, scalar: ephPrivateKey, ctx: ctx)
                    .flatMap { dh2 in
                        ECPointUtils.pointMul(group: group, point: ephSPub, scalar: statPrivateKey, ctx: ctx)
                            .flatMap { dh3 in

                                defer {
                                    EC_POINT_free(dh1)
                                    EC_POINT_free(dh2)
                                    EC_POINT_free(dh3)
                                }
                                
                                return ECPointUtils.compressPoint(dh1, group: group, ctx: ctx)
                                    .flatMap { c1 in
                                        ECPointUtils.compressPoint(dh2, group: group, ctx: ctx)
                                            .flatMap { c2 in
                                                ECPointUtils.compressPoint(dh3, group: group, ctx: ctx)
                                                    .map { c3 in
                                                        return c1 + c2 + c3
                                                    }
                                            }
                                    }
                            }
                    }
            }
    }
    
    
    
    static func bignumToData(_ bn: UnsafePointer<BIGNUM>) -> Data {
        let length = (BN_num_bits(bn) + 7) / 8
        var buffer = Data(repeating: 0, count: Int(length))

        _ = buffer.withUnsafeMutableBytes {
            BN_bn2bin(bn, $0.baseAddress?.assumingMemoryBound(to: UInt8.self))
        }

        return buffer
    }
    
    
    static func printAkeInputs(
        ephPrivateKey: UnsafePointer<BIGNUM>,
        statPrivateKey: UnsafePointer<BIGNUM>,
        statSPub: OpaquePointer,
        ephSPub: OpaquePointer,
        group: OpaquePointer
    ) {
        guard let ctx = BN_CTX_new() else {
            print("❌ Failed to allocate BN_CTX")
            return
        }
        defer { BN_CTX_free(ctx) }

        let ephPrivBytes = bignumToData(ephPrivateKey)
        let statPrivBytes = bignumToData(statPrivateKey)

        let statSPubBytesResult = ECPointUtils.compressPoint(statSPub, group: group, ctx: ctx)
        guard case let .success(statSPubBytes) = statSPubBytesResult else {
            return
        }
        
        let ephSPubBytesResult = ECPointUtils.compressPoint(ephSPub, group: group, ctx: ctx)
        guard case let .success(ephSPubBytes) = ephSPubBytesResult else {
            return
        }

        print("🟦 ephPrivateKey: \(ephPrivBytes.hexEncodedString())")
        print("🟩 statPrivateKey: \(statPrivBytes.hexEncodedString())")
        print("🟨 statSPub (compressed): \(statSPubBytes.hexEncodedString())")
        print("🟧 ephSPub (compressed): \(ephSPubBytes.hexEncodedString())")
    }


}
