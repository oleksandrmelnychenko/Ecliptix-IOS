//
//  CircuitBreaker.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 07.07.2025.
//

import Foundation

final class CircuitBreaker {
    private let maxFailures: Int
    private let resetTimeout: TimeInterval
    private let onBreak: () -> Void
    private let onReset: () -> Void

    private var failureCount: Int = 0
    private var openUntil: Date?

    init(
        maxFailures: Int,
        resetTimeout: TimeInterval,
        onBreak: @escaping () -> Void = {},
        onReset: @escaping () -> Void = {}
    ) {
        self.maxFailures = maxFailures
        self.resetTimeout = resetTimeout
        self.onBreak = onBreak
        self.onReset = onReset
    }

    func execute<T>(_ block: @escaping () async throws -> T) async throws -> T {
        if let openUntil, Date() < openUntil {
            throw BrokenCircuitException()
        }

        do {
            let result = try await block()
            reset()
            return result
        } catch {
            if Self.shouldRetry(error, conditions: [RetryCondition.isUnauthorizedError]) {
                failureCount += 1
                if failureCount >= maxFailures {
                    openUntil = Date().addingTimeInterval(resetTimeout)
                    onBreak()
                }
            }
            throw error
        }
    }

    private func reset() {
        if failureCount > 0 {
            onReset()
        }
        failureCount = 0
        openUntil = nil
    }
    
    private static func shouldRetry(_ error: Error, conditions: [(Error) -> Bool]) -> Bool {
        return conditions.contains { $0(error) }
    }
}
