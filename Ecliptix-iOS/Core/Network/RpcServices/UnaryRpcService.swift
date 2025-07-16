//
//  SingleCallExecutor.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import Foundation
import GRPC
import SwiftProtobuf

final class UnaryRpcService {
    private let membershipClient: Ecliptix_Proto_Membership_MembershipServicesAsyncClient
    private let appDeviceClient: Ecliptix_Proto_AppDevice_AppDeviceServiceActionsAsyncClient
    private let authClient: Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient
    
    private var serviceMethods: [RpcServiceType: GrpcMethodDelegate] = [:]
    typealias GrpcMethodDelegate = (
        _ payload: Ecliptix_Proto_CipherPayload,
        _ networkEvents: NetworkEventsProtocol,
        _ systemEvents: SystemEventsProtocol,
        _ token: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, NetworkFailure>

    init(
        membershipClient: Ecliptix_Proto_Membership_MembershipServicesAsyncClient,
        appDeviceClient: Ecliptix_Proto_AppDevice_AppDeviceServiceActionsAsyncClient,
        authClient: Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient
    ) {
        self.membershipClient = membershipClient
        self.appDeviceClient = appDeviceClient
        self.authClient = authClient
        
        self.serviceMethods = [
            .registerAppDevice: registerDeviceAsync,
            .validatePhoneNumber: validatePhoneNumberAsync,
            .opaqueRegistrationInit: opaqueRegistrationRecordRequestAsync,
            .verifyOtp: verifyCodeAsync,
            .opaqueRegistrationComplete: opaqueRegistrationCompleteRequestAsync,
            .opaqueSignInInitRequest: opaqueSignInInitRequestAsync,
            .opaqueSignInCompleteRequest: opaqueSignInCompleteRequestAsync,
            .opaqueRecoverySecretKeyInitRequest: opaqueRecoverySecretKeyInitRequestAsync,
            .opaqueRecoverySecretKeyCompleteRequest: opaqueRecoverySecretKeyCompleteRequestAsync
        ]
    }

    func invokeRequestAsync(
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        request: ServiceRequest,
        token: CancellationToken
    ) async -> Result<RpcFlow, NetworkFailure> {
        guard let handler = self.serviceMethods[request.rcpServiceMethod] else {
            return .failure(.invalidRequestType("Unsupported service method"))
        }
        
        do {
            let task = try await handler(request.payload, networkEvents, systemEvents, token)
            
            switch task {
            case .success:
                return .success(RpcFlow.SingleCall(immediate: task))
            case .failure:
                return .failure(try task.unwrapErr())
            }
        } catch {
            return .failure(.unexpectedError("Invocation failed", inner: error))
        }
    }
    
    private func registerDeviceAsync(
        payload: Ecliptix_Proto_CipherPayload,
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, NetworkFailure> {
        return await Self.executeGrpcCallAsync(networkEvents: networkEvents, systemEvents: systemEvents) {
            return try await self.appDeviceClient.registerDeviceAppIfNotExist(payload)
        }
    }

    private func validatePhoneNumberAsync(
        payload: Ecliptix_Proto_CipherPayload,
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, NetworkFailure> {
        
        
        return await Self.executeGrpcCallAsync(networkEvents: networkEvents, systemEvents: systemEvents) {
            try await self.authClient.validatePhoneNumber(payload)
        }
    }

    private func verifyCodeAsync(
        payload: Ecliptix_Proto_CipherPayload,
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, NetworkFailure> {
        
        return await Self.executeGrpcCallAsync(networkEvents: networkEvents, systemEvents: systemEvents) {
            try await self.authClient.verifyOtp(payload)
        }
    }
    
    private func opaqueRegistrationRecordRequestAsync(
        payload: Ecliptix_Proto_CipherPayload,
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, NetworkFailure> {
        return await Self.executeGrpcCallAsync(networkEvents: networkEvents, systemEvents: systemEvents) {
            try await self.membershipClient.opaqueRegistrationInitRequest(payload)
        }
    }
    
    private func opaqueRegistrationCompleteRequestAsync(
        payload: Ecliptix_Proto_CipherPayload,
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, NetworkFailure> {
        return await Self.executeGrpcCallAsync(networkEvents: networkEvents, systemEvents: systemEvents) {
            try await self.membershipClient.opaqueRegistrationCompleteRequest(payload)
        }
    }
    
    private func opaqueSignInInitRequestAsync(
        payload: Ecliptix_Proto_CipherPayload,
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, NetworkFailure> {
        return await Self.executeGrpcCallAsync(networkEvents: networkEvents, systemEvents: systemEvents) {
            try await self.membershipClient.opaqueSignInInitRequest(payload)
        }
    }

    private func opaqueSignInCompleteRequestAsync(
        payload: Ecliptix_Proto_CipherPayload,
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, NetworkFailure> {
        return await Self.executeGrpcCallAsync(networkEvents: networkEvents, systemEvents: systemEvents) {
            try await self.membershipClient.opaqueSignInCompleteRequest(payload)
        }
    }
    
    private func opaqueRecoverySecretKeyInitRequestAsync(
        payload: Ecliptix_Proto_CipherPayload,
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, NetworkFailure> {
        return await Self.executeGrpcCallAsync(networkEvents: networkEvents, systemEvents: systemEvents) {
            try await self.membershipClient.opaqueRecoverySecretKeyInitRequest(payload)
        }
    }
    
    private func opaqueRecoverySecretKeyCompleteRequestAsync(
        payload: Ecliptix_Proto_CipherPayload,
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, NetworkFailure> {
        return await Self.executeGrpcCallAsync(networkEvents: networkEvents, systemEvents: systemEvents) {
            try await self.membershipClient.opaqueRecoverySecretKeyCompleteRequest(payload)
        }
    }
    
    private static func executeGrpcCallAsync(
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        _ grpcCallFactory: @escaping () async throws -> Ecliptix_Proto_CipherPayload
    ) async -> Result<Ecliptix_Proto_CipherPayload, NetworkFailure> {
        
        return await Result<Ecliptix_Proto_CipherPayload, NetworkFailure>.TryAsync {
            let response = try await GrpcResiliencePolicies.getSecrecyChannelRetryPolicy(networkEvents: networkEvents) {
                try await grpcCallFactory()
            }
            
            networkEvents.initiateChangeState(.new(.dataCenterDisconnected))
            
            return response
        } errorMapper: { error in
            systemEvents.publish(.new(.dataCenterShutdown))

            let message: String
            if let grpcStatus = error as? GRPCStatus {
                message = grpcStatus.message ?? grpcStatus.description
            } else {
                message = error.localizedDescription
            }

            return .dataCenterShutdown(message, inner: error)
        }
    }
}

