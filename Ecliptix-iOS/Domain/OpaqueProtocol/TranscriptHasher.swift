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
        return EVPCryptoUtils.withEvpCtx { ctx in
            let inputs = [
                OpaqueConstants.protocolVersion,
                Data(phoneNumber.utf8),
                oprfResponse,
                clientStaticPublicKey,
                clientEphemeralPublicKey,
                serverStaticPublicKey,
                serverEphemeralPublicKey
            ]

            return EVPCryptoUtils.evpHash(ctx: ctx, inputs: inputs)
        }
    }
}
