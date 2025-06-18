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
        maxRetryCount:     Int  = 3,
        backoff:           RetryBackoff = .init(),
        retryConditions:   [(Error) -> Bool],
        _ block:           @escaping () async throws -> Output
    ) async -> Result<Output, EcliptixProtocolFailure> {
        
        var attempts = 0
        
        while attempts < maxRetryCount {
            attempts += 1
            do {
                let value = try await block()
                return .success(value)
            } catch {
                let shouldRetry = retryConditions.contains { $0(error) }
                
                guard shouldRetry else {
                    return .failure(.generic("Operation failed", inner: error))
                }
                
                if attempts == maxRetryCount {
                    return .failure(.generic("Retry attempts exhausted", inner: error))
                }
                
                let delay = backoff.delay(for: attempts)
                try? await Task.sleep(nanoseconds: delay)
            }
        }
        
        return .failure(.generic("Retry logic failed unexpectedly."))
    }
    
    static func execute<Output>(
        maxRetryCount:   Int  = 3,
        backoff:         RetryBackoff = .init(),
        retryCondition:  @escaping (Error) -> Bool,
        _ block:         @escaping () async throws -> Output
    ) async -> Result<Output, EcliptixProtocolFailure> {
        await execute(
            maxRetryCount:   maxRetryCount,
            backoff:         backoff,
            retryConditions: [retryCondition],
            block
        )
    }
}
