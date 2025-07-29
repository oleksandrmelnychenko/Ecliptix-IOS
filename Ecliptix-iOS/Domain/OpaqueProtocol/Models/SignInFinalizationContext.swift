//
//  SignInFinalizationContext.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 28.07.2025.
//

import Foundation

struct SignInFinalizationContext {
    let clientEphemeralPublicKey: Data
    let sessionKeys: SessionKeys
    let transcriptHash: Data
}
