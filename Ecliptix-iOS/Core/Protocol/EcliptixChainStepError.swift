//
//  ShieldChainStepError.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 22.05.2025.
//

import Foundation

public struct EcliptixChainStepError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? {
        return message
    }
}
