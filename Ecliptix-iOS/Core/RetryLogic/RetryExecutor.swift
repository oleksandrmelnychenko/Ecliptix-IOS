//
//  RetryExecutor.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 18.06.2025.
//

import Foundation
import GRPC

final class RetryExecutor {
    
    private static let defaultMaxRetryCount: Int = 3
    
    // MARK: - Async
    static func executeAsync<Output>(
        maxRetryCount: Int? = defaultMaxRetryCount,
        backoff: RetryBackoff = .init(),
        retryConditions: [(Error) -> Bool] = [],
        onRetry: ((Int, Error) async -> Void)? = nil,
        _ block: @escaping () async throws -> Output
    ) async throws -> Output {
        var attempts = 0

        while true {
            attempts += 1
            do {
                return try await block()
            } catch {
                if !shouldRetry(error, conditions: retryConditions) || (maxRetryCount != nil && attempts >= maxRetryCount!) {
                    throw error
                }

                if let onRetry = onRetry {
                    await onRetry(attempts, error)
                }

                try? await Task.sleep(nanoseconds: delay(for: attempts, backoff: backoff))
            }
        }
    }

    // MARK: - Sync
    static func execute<Output>(
        maxRetryCount: Int? = defaultMaxRetryCount,
        backoff: RetryBackoff = .init(),
        retryConditions: [(Error) -> Bool] = [],
        onRetry: ((Int, Error) -> Void)? = nil,
        _ block: () throws -> Output
    ) throws -> Output {
        var attempts = 0

        while true {
            attempts += 1
            do {
                return try block()
            } catch {
                if !shouldRetry(error, conditions: retryConditions) || (maxRetryCount != nil && attempts >= maxRetryCount!) {
                    throw error
                }

                onRetry?(attempts, error)
                Thread.sleep(forTimeInterval: TimeInterval(delay(for: attempts, backoff: backoff)) / 1_000_000_000.0)
            }
        }
    }
    
    private static func shouldRetry(_ error: Error, conditions: [(Error) -> Bool]) -> Bool {
        return conditions.contains { $0(error) }
    }
    
    private static func delay(for attempts: Int, backoff: RetryBackoff) -> UInt64 {
        if attempts % 10 == 0 {
            return 60 * 1_000_000_000 // 60 seconds
        } else {
            return backoff.delay(for: attempts)
        }
    }
}

extension RetryExecutor {
    static func executeResult<Success, Failure: Error>(
        maxRetryCount: Int? = defaultMaxRetryCount,
        backoff: RetryBackoff = .init(),
        retryCondition: @escaping (Result<Success, Failure>) -> Bool,
        onRetry: ((Int, Result<Success, Failure>) async -> Void)? = nil,
        _ block: @escaping () async -> Result<Success, Failure>
    ) async -> Result<Success, Failure> {
        var attempts = 0

        while true {
            attempts += 1
            let result = await block()
            if result.isOk {
                return result
            }
            
            let shouldRetry = retryCondition(result)
            if !shouldRetry {
                return result
            }
            
            if let maxRetry = maxRetryCount, attempts >= maxRetry {
                return result
            }

            if let onRetry = onRetry {
                await onRetry(attempts, result)
            }

            try? await Task.sleep(nanoseconds: delay(for: attempts, backoff: backoff))
        }
    }
}
