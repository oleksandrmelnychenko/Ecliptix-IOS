//
//  SingleCallExecutor.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import SwiftProtobuf

public final class SingleCallExecutor {
    let membershipServicesClient: Ecliptix_Proto_Membership_MembershipServices.ClientProtocol
    let appDeviceServiceActionsClient: Ecliptix_Proto_AppDevice_AppDeviceServiceActions.ClientProtocol
    let authenticationServicesClient: Ecliptix_Proto_Membership_AuthVerificationServices.ClientProtocol
    
    init(membershipServicesClient: Ecliptix_Proto_Membership_MembershipServices.ClientProtocol, appDeviceServiceActionsClient: Ecliptix_Proto_AppDevice_AppDeviceServiceActions.ClientProtocol, authenticationServicesClient: Ecliptix_Proto_Membership_AuthVerificationServices.ClientProtocol) {
        self.membershipServicesClient = membershipServicesClient
        self.appDeviceServiceActionsClient = appDeviceServiceActionsClient
        self.authenticationServicesClient = authenticationServicesClient
    }
    
    public func invokeRequestAsync(request: ServiceRequest, token: CancellationToken) async -> Result<RpcFlow, EcliptixProtocolFailure> {
        switch request.rcpServiceMethod {
        case .dataCenterPubKeyExchange:
            return .failure(EcliptixProtocolFailure.generic())
        case .registerAppDevice:
            let resultTask = Task { await registerDeviceAsync(payload: request.payload, token: token) }
            return .success(RpcFlow.SingleCall(result: resultTask))
        case .validatePhoneNumber:
            let validatePhoneNumberResultTask = Task { await validatePhoneNumber(payload: request.payload, token: token) }
            return .success(RpcFlow.SingleCall(result: validatePhoneNumberResultTask))
        case .varifyOtp:
            let verifyWithCodeResultTask = Task { await verifyCodeAsync(payload: request.payload, token: token) }
            return .success(RpcFlow.SingleCall(result: verifyWithCodeResultTask))
        case .initiateVerification:
            return .failure(EcliptixProtocolFailure.generic())
        case .signIn:
            let signInResultTask = Task { await signInAsync(payload: request.payload, token: token) }
            return .success(RpcFlow.SingleCall(result: signInResultTask))
        case .updateMembershipWithSecureKey:
            let createMembershipResultTask = Task { await updateMembershipWithSecureKeyAsync(payload: request.payload, token: token) }
            return .success(RpcFlow.SingleCall(result: createMembershipResultTask))
        }
    }
    
    private func updateMembershipWithSecureKeyAsync(payload: Ecliptix_Proto_CipherPayload, token: CancellationToken) async -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        
        return await Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>.TryAsync {
            try Task.checkCancellation()
            if token.cancelled {
                throw EcliptixProtocolFailure.generic("Operation was cancelled")
            }

            let responce = try await self.membershipServicesClient.updateMembershipWithSecureKey(payload)
            return responce
        }.mapError { error in
            return .generic(error.message, inner: error.innerError)
        }
    }
    
    private func signInAsync(payload: Ecliptix_Proto_CipherPayload, token: CancellationToken) async -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        
        return await Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>.TryAsync {
            try Task.checkCancellation()
            if token.cancelled {
                throw EcliptixProtocolFailure.generic("Operation was cancelled")
            }

            let responce = try await self.membershipServicesClient.signInMembership(payload)
            return responce
        }.mapError { error in
            return .generic(error.message, inner: error.innerError)
        }
    }
    
    private func validatePhoneNumber(payload: Ecliptix_Proto_CipherPayload, token: CancellationToken) async -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        
        return await Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>.TryAsync {
            try Task.checkCancellation()
            if token.cancelled {
                throw EcliptixProtocolFailure.generic("Operation was cancelled")
            }

            let responce = try await self.authenticationServicesClient.validatePhoneNumber(payload)
            return responce
        }.mapError { error in
            return .generic(error.message, inner: error.innerError)
        }
    }
    
    private func verifyCodeAsync(payload: Ecliptix_Proto_CipherPayload, token: CancellationToken) async -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        
        return await Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>.TryAsync {
            try Task.checkCancellation()
            if token.cancelled {
                throw EcliptixProtocolFailure.generic("Operation was cancelled")
            }

            let responce = try await self.authenticationServicesClient.verifyOtp(payload)
            return responce
        }.mapError { error in
            return .generic(error.message, inner: error.innerError)
        }
    }
    
    private func registerDeviceAsync(payload: Ecliptix_Proto_CipherPayload, token: CancellationToken) async -> Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure> {
        
        return await Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>.TryAsync {
            try Task.checkCancellation()
            if token.cancelled {
                throw EcliptixProtocolFailure.generic("Operation was cancelled")
            }
            
            let response = try await self.appDeviceServiceActionsClient.registerDeviceAppIfNotExist(payload)
            return response
        }.mapError { error in
            return .generic(error.message, inner: error.innerError)
        }
    }
}
