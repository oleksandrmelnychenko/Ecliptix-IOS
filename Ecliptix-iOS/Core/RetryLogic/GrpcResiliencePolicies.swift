//
//  GrpcResiliencePolicies.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 07.07.2025.
//

import Foundation

public enum GrpcResiliencePolicies {
    static func getAuthenticatedPolicy<Output>(
        networkProvider: NetworkProviderProtocol,
        _ block: @escaping () async throws -> Output
    ) async throws -> Output {
        let circuitBreaker = CircuitBreaker(
            maxFailures: 2,
            resetTimeout: 30,
            onBreak: {
                print("Circuit breaker opened for 30 seconds due to unauthorized failure")
                networkProvider.setSecrecyChannelAsUnhealthy()
            },
            onReset: {
                print("Circuit breaker reset")
            }
        )

        return try await RetryExecutor.execute(
            maxRetryCount: 3,
            backoff: RetryBackoff(baseDelay: 1_000_000_000), // 1s, 2s, 3s
            retryConditions: [
                RetryCondition.grpcUnavailableOnly,
                RetryCondition.grpcDeadlineExceededOnly,
                RetryCondition.grpcResourceExhaustedOnly
            ],
            onRetry: { attempt, error in
                print("Transient failure. Retrying in \(attempt) seconds. Attempt \(attempt)/3. Error: \(error)")
            }
        ) {
            try await sessionRecoveryWrapper(networkProvider: networkProvider) {
                try await circuitBreaker.execute {
                    try await block()
                }
            }
        }.unwrap()
    }
    
    static func getUnauthenticatedRetryPolicy<Output>(
        _ block: @escaping () async throws -> Output
    ) async throws -> Output {
        let backoff = RetryBackoff(
            baseDelay: 2_000_000_000, // 2s
            maxDelay: 6_000_000_000,  // 6s
            multiplier: 1.0,          // 2s, 4s, 6s
            jitter: 0.0               // no jitter
        )

        let result = try await RetryExecutor.execute(
            maxRetryCount: 3,
            backoff: backoff,
            retryConditions: [
                { error in error is URLError }, // HttpRequestException
                RetryCondition.grpcUnavailableOnly,
                RetryCondition.grpcDeadlineExceededOnly,
                RetryCondition.grpcResourceExhaustedOnly
            ],
            onRetry: { attempt, error in
                print("Unauthenticated call failed. Retrying in \(attempt * 2) seconds. Attempt \(attempt)/3. Error: \(error)")
            },
            block
        )

        return try result.unwrap()
    }
    
    static func getSecrecyChannelRetryPolicy<Output>(
        _ block: @escaping () async throws -> Output
    ) async throws -> Output {
        
        let backoff = RetryBackoff(
            baseDelay: 10_000_000_000, // 10s
            maxDelay: 30_000_000_000,  // 30s (3rd retry)
            multiplier: 1.0,           // 10s, 20s, 30s
            jitter: 0.0                // no jitter for simplicity
        )
        
        let result = try await RetryExecutor.execute(
            maxRetryCount: 3,
            backoff: backoff,
            retryConditions: [
                RetryCondition.grpcUnavailableOnly,
                RetryCondition.grpcDeadlineExceededOnly,
                RetryCondition.grpcResourceExhaustedOnly
            ],
            onRetry: { attempt, error in
                print("gRPC call failed. Retrying in \(attempt * 10) seconds. Attempt \(attempt)/3. Error: \(error)")
            },
            block
        )
        
        return try result.unwrap()
    }
    
    static func sessionRecoveryWrapper<Output>(
        networkProvider: NetworkProviderProtocol,
        maxAttempts: Int = 2,
        _ block: @escaping () async throws -> Output
    ) async throws -> Output {
        for attempt in 1...maxAttempts {
            do {
                return try await block()
            } catch is BrokenCircuitException {
                print("Circuit broken. Attempting session recovery (\(attempt)/\(maxAttempts))")
                let result = await networkProvider.restoreSecrecyChannelAsync()

                if result.isErr {
                    let err = try result.unwrapErr()
                    print("Session recovery failed: \(err.message)")
                    throw SessionRecoveryException(message: "Failed to recover session", inner: err.innerError)
                }

                print("Session recovered on attempt \(attempt)")
            }
        }

        throw SessionRecoveryException(message: "Session recovery exhausted", inner: nil)
    }
}
