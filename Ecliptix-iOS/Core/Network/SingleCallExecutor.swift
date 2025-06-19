//
//  SingleCallExecutor.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import Foundation
import GRPC
import SwiftProtobuf

final class SingleCallExecutor {
    private let membershipClient: Ecliptix_Proto_Membership_MembershipServicesAsyncClient
    private let appDeviceClient: Ecliptix_Proto_AppDevice_AppDeviceServiceActionsAsyncClient
    private let authClient: Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient
    
    init(
        membershipClient: Ecliptix_Proto_Membership_MembershipServicesAsyncClient,
        appDeviceClient: Ecliptix_Proto_AppDevice_AppDeviceServiceActionsAsyncClient,
        authClient: Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient
    ) {
        self.membershipClient = membershipClient
        self.appDeviceClient = appDeviceClient
        self.authClient = authClient
    }

    func invokeRequestAsync(
        request: ServiceRequest,
        cancellation: CancellationToken
    ) async throws -> Result<RpcFlow, EcliptixProtocolFailure> {
        do {
            switch request.rcpServiceMethod {
            case .registerAppDevice:
                return try await wrapCall {
                    try await self.registerDeviceAsync(payload: request.payload, cancellation: cancellation)
                }
            
            case .validatePhoneNumber:
                return try await wrapCall {
                    try await self.validatePhoneNumberAsync(payload: request.payload, cancellation: cancellation)
                }

            case .signIn:
                return try await wrapCall {
                    try await self.signInAsync(payload: request.payload, cancellation: cancellation)
                }

            case .updateMembershipWithSecureKey:
                return try await wrapCall {
                    try await self.updateMembershipWithSecureKeyAsync(payload: request.payload, cancellation: cancellation)
                }

            case .verifyOtp:               
                return try await wrapCall {
                    try await self.verifyCodeAsync(payload: request.payload, cancellation: cancellation)
                }

            default:
                return .failure(.generic("Unsupported service method"))
            }
        } catch {
            throw error
        }
    }

    private func wrapCall(
        _ block: @escaping () async throws -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>
    ) async throws -> Result<RpcFlow, EcliptixProtocolFailure> {
        let task = try await block()

        if task.isOk {
            return .success(RpcFlow.SingleCall(result: task))
        } else {
            return .failure(try task.unwrapErr())
        }
    }
    
    private func registerDeviceAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        return try await RetryExecutor.execute(retryCondition: RetryCondition.grpcUnavailableOnly,
            {
                try await self.appDeviceClient.registerDeviceAppIfNotExist(payload)
            }
        )
    }

    private func validatePhoneNumberAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        return try await RetryExecutor.execute(retryCondition: RetryCondition.grpcUnavailableOnly,
            {
                try await self.authClient.validatePhoneNumber(payload)
            }
        )
    }

    private func verifyCodeAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        
        return try await RetryExecutor.execute(retryCondition: RetryCondition.grpcUnavailableOnly,
            {
                try await self.authClient.verifyOtp(payload)
            }
        )
    }

    private func signInAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        return try await RetryExecutor.execute(retryCondition: RetryCondition.grpcUnavailableOnly,
            {
                try await self.membershipClient.signInMembership(payload)
            }
        )
    }

    private func updateMembershipWithSecureKeyAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {

        return try await RetryExecutor.execute(retryCondition: RetryCondition.grpcUnavailableOnly,
            {
                try await self.membershipClient.updateMembershipWithSecureKey(payload)
            }
        )
    }
}

