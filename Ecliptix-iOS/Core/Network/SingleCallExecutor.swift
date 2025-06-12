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
    ) async -> Result<RpcFlow, EcliptixProtocolFailure> {
        switch request.rcpServiceMethod {
        case .registerAppDevice:
            let task = await registerDeviceAsync(payload: request.payload, cancellation: cancellation)
            return .success(RpcFlow.SingleCall(result: task))

        case .validatePhoneNumber:
            let task = await validatePhoneNumberAsync(payload: request.payload, cancellation: cancellation)
            return .success(RpcFlow.SingleCall(result: task))

        case .signIn:
            let task = await signInAsync(payload: request.payload, cancellation: cancellation)
            return .success(RpcFlow.SingleCall(result: task))

        case .updateMembershipWithSecureKey:
            let task = await updateMembershipWithSecureKeyAsync(payload: request.payload, cancellation: cancellation)
            return .success(RpcFlow.SingleCall(result: task))

        case .verifyOtp:
            let task = await verifyCodeAsync(payload: request.payload, cancellation: cancellation)
            return .success(RpcFlow.SingleCall(result: task))

        default:
            return .failure(.generic("Unsupported service method"))
        }
    }

    private func registerDeviceAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        return await Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>.TryAsync {
            let response = try await self.appDeviceClient.registerDeviceAppIfNotExist(payload)
            return response
        }.mapError { error in
            return .generic(error.localizedDescription, inner: error)
        }
    }

    private func validatePhoneNumberAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        return await Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>.TryAsync {
            let response = try await self.authClient.validatePhoneNumber(payload)
            return response
        }.mapError { error in
            return .generic(error.localizedDescription, inner: error)
        }
    }

    private func verifyCodeAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        return await Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>.TryAsync {
            let response = try await self.authClient.verifyOtp(payload)
            return response
        }.mapError { error in
            return .generic(error.localizedDescription, inner: error)
        }
    }

    private func signInAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        return await Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>.TryAsync {
            let response = try await self.membershipClient.signInMembership(payload)
            return response
        }.mapError { error in
            return .generic(error.localizedDescription, inner: error)
        }
    }

    private func updateMembershipWithSecureKeyAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        return await Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>.TryAsync {
            let response = try await self.membershipClient.updateMembershipWithSecureKey(payload)
            return response
        }.mapError { error in
            return .generic(error.localizedDescription, inner: error)
        }
    }
}

