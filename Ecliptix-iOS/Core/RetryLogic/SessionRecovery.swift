//
//  SessionRecovery.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 07.07.2025.
//

struct BrokenCircuitException: Error {}
struct SessionRecoveryException: Error {
    let message: String
    let inner: Error?
}
