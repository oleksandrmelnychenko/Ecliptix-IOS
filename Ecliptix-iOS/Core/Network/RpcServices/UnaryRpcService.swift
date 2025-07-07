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
    typealias GrpcMethodDelegate = (_ payload: Ecliptix_Proto_CipherPayload, _ token: CancellationToken) async throws -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>

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
            .opaqueSignInCompleteRequest: opaqueSignInCompleteRequestAsync
        ]
    }

    func invokeRequestAsync(
        request: ServiceRequest,
        token: CancellationToken
    ) async -> Result<RpcFlow, EcliptixProtocolFailure> {
        guard let handler = self.serviceMethods[request.rcpServiceMethod] else {
            return .failure(.invalidInput("Unsupported method"))
        }
        
        do {
            let task = try await handler(request.payload, token)
            
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
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        let options = CallOptions(timeLimit: .timeout(.seconds(20)))
        
        return await Self.executeGrpcCallAsync {
            return try await self.appDeviceClient.registerDeviceAppIfNotExist(payload, callOptions: options)
        }
    }

    private func validatePhoneNumberAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        
        
        return await Self.executeGrpcCallAsync {
            try await self.authClient.validatePhoneNumber(payload)
        }
    }

    private func verifyCodeAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        
        return await Self.executeGrpcCallAsync {
            try await self.authClient.verifyOtp(payload)
        }
    }
    
    private func opaqueRegistrationRecordRequestAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        return await Self.executeGrpcCallAsync {
            try await self.membershipClient.opaqueRegistrationInitRequest(payload)
        }
    }
    
    private func opaqueRegistrationCompleteRequestAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        return await Self.executeGrpcCallAsync {
            try await self.membershipClient.opaqueRegistrationCompleteRequest(payload)
        }
    }
    
    private func opaqueSignInInitRequestAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        return await Self.executeGrpcCallAsync {
            try await self.membershipClient.opaqueSignInInitRequest(payload)
        }
    }

    private func opaqueSignInCompleteRequestAsync(
        payload: Ecliptix_Proto_CipherPayload,
        cancellation: CancellationToken
    ) async throws -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        return await Self.executeGrpcCallAsync {
            try await self.membershipClient.opaqueSignInCompleteRequest(payload)
        }
    }
    
    private static func executeGrpcCallAsync(
        _ grpcCallFactory: @escaping () async throws -> Ecliptix_Proto_CipherPayload
    ) async -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        
//        return await Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>.TryAsync {
//            try await RetryExecutor.execute(maxRetryCount: nil, retryConditions: conditions) {
//                try await grpcCallFactory()
//            }.unwrap()
//        }.mapError { error in
//            EcliptixProtocolFailure.generic(error.message, inner: error.innerError)
//        }
        
        
        return await Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>.TryAsync {
            try await GrpcResiliencePolicies.getAuthenticatedPolicy(networkProvider: ServiceLocator.shared.resolve(NetworkProviderProtocol.self)) {
                try await grpcCallFactory()
            }
        }
        .mapError { error in
            EcliptixProtocolFailure.generic(error.message, inner: error.innerError)
        }
    }
}

