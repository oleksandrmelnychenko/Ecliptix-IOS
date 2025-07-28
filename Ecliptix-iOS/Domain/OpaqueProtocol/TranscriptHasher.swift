//
//  TranscriptHasher.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 01.07.2025.
//

import Foundation
import OpenSSL

enum TranscriptHasher {
    static func hash(
        phoneNumber: String,
        oprfResponse: Data,
        clientStaticPublicKey: Data,
        clientEphemeralPublicKey: Data,
        serverStaticPublicKey: Data,
        serverEphemeralPublicKey: Data
    ) -> Result<Data, OpaqueFailure> {
        guard let ctx = EVP_MD_CTX_new() else {
            return .failure(.hashFailed("Failed to create hash context"))
        }
        
        defer {
            EVP_MD_CTX_free(ctx)
        }

        guard EVP_DigestInit_ex(ctx, EVP_sha256(), nil) == 1 else {
            return .failure(.hashFailed("Failed to initialize digest"))
        }

        for part in [
            OpaqueConstants.protocolVersion,
            Data(phoneNumber.utf8),
            oprfResponse,
            clientStaticPublicKey,
            clientEphemeralPublicKey,
            serverStaticPublicKey,
            serverEphemeralPublicKey
        ] {
            guard update(part, ctx: ctx) else {
                EVP_MD_CTX_free(ctx)
                return .failure(.hashFailed("Failed to update digest"))
            }
        }

        return digestFinal(ctx: ctx)
    }
    
    private static func update(_ data: Data, ctx: OpaquePointer) -> Bool {
        data.withUnsafeBytes {
            EVP_DigestUpdate(ctx, $0.baseAddress, data.count) == 1
        }
    }
    
    private static func digestFinal(ctx: OpaquePointer) -> Result<Data, OpaqueFailure> {
        var hash = Data(repeating: 0, count: 32)
        var outLen: UInt32 = 0
        let success = hash.withUnsafeMutableBytes {
            EVP_DigestFinal_ex(ctx, $0.baseAddress?.assumingMemoryBound(to: UInt8.self), &outLen) == 1
        }
        
        return success
            ? .success(hash)
            : .failure(.hashFailed("Failed to finalize digest"))
    }
}

