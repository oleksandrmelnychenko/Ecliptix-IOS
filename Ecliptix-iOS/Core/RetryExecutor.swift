//
//  RetryExecutor.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 18.06.2025.
//

import Foundation
import GRPC

final class RetryExecutor {
    
    static func execute<Output>(
        maxRetryCount: Int = 3,
        delayBetweenRetries: UInt64 = 3_000_000_000,
        retryConditions: [(Error) -> Bool],
        _ block: @escaping () async throws -> Output
    ) async -> Result<Output, EcliptixProtocolFailure> {
        
        var attempts = 0
        
        while attempts < maxRetryCount {
            attempts += 1
            
            do {
                let result = try await block()
                return .success(result)
            } catch {
                let shouldRetry = retryConditions.contains { $0(error) }

                if shouldRetry {
                    if attempts == maxRetryCount {
                        return .failure(.generic("Retry attempts exhausted", inner: error))
                    }
                    try? await Task.sleep(nanoseconds: delayBetweenRetries)
                    continue
                } else {
                    return .failure(.generic("Operation failed", inner: error))
                }
            }
        }
        
        return .failure(.generic("Retry logic failed unexpectedly."))
    }
}

extension RetryExecutor {
    static func execute<Output>(
        maxRetryCount: Int = 3,
        delayBetweenRetries: UInt64 = 3_000_000_000,
        retryCondition: @escaping (Error) -> Bool,
        _ block: @escaping () async throws -> Output
    ) async -> Result<Output, EcliptixProtocolFailure> {
        await execute(
            maxRetryCount: maxRetryCount,
            delayBetweenRetries: delayBetweenRetries,
            retryConditions: [retryCondition],
            block
        )
    }
}
