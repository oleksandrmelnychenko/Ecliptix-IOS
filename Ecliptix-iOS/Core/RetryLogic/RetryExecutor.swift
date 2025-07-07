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
    
    static func execute<Output>(
        maxRetryCount:     Int? = defaultMaxRetryCount,  // nil = infinite
        backoff:           RetryBackoff = .init(),
        retryConditions:   [(Error) -> Bool] = [RetryCondition.grpcUnavailableOnly],
        onRetry: ((Int, Error) -> Void)? = nil,
        _ block: @escaping () async throws -> Output
    ) async throws -> Result<Output, EcliptixProtocolFailure> {
        
        var attempts = 0

        while true {
            attempts += 1
            do {
                let value = try await block()
                return .success(value)
            } catch {
                if !shouldRetry(error, conditions: retryConditions) {
                    throw error
                }

                if let maxRetry = maxRetryCount, attempts >= maxRetry {
                    return .failure(.generic("Retry attempts exhausted", inner: error))
                }

                onRetry?(attempts, error)

                if attempts % 10 == 0 {
                    try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                } else {
                    let delay = backoff.delay(for: attempts)
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }
    }
    
    static func execute<Output>(
        maxRetryCount:   Int  = 3,
        backoff:         RetryBackoff = .init(),
        retryCondition:  @escaping (Error) -> Bool = RetryCondition.grpcUnavailableOnly,
        onRetry:         ((Int, Error) -> Void)? = nil,
        _ block:         @escaping () async throws -> Output
    ) async throws -> Result<Output, EcliptixProtocolFailure> {
        try await execute(
                maxRetryCount:   maxRetryCount,
                backoff:         backoff,
                retryConditions: [retryCondition],
                onRetry: onRetry,
                block
        )
    }
    
    private static func shouldRetry(_ error: Error, conditions: [(Error) -> Bool]) -> Bool {
        return conditions.contains { $0(error) }
    }
}
