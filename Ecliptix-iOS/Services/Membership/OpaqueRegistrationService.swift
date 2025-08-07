//
//  OpaqueRegistrationService.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 01.08.2025.
//

import Foundation

struct OpaqueRegistrationService {
    private let networkProvider: NetworkProvider
    private let authFlow: AuthFlow
    
    init(networkProvider: NetworkProvider, authFlow: AuthFlow) {
        self.networkProvider = networkProvider
        self.authFlow = authFlow
    }
    
    func signUpAsync(
        securePassword: SecureTextBuffer
    ) async -> Result<Unit, InternalValidationFailure> {
        do {
            
            var passwordBytes: Data?
            try securePassword.withSecureBytes { bytes in
                passwordBytes = bytes
            }
            if passwordBytes == nil || passwordBytes!.isEmpty {
                return .failure(.invalidValue(Strings.ValidationErrors.SecureKey.required))
            }
            
            // Retrive membership
           return await ViewModelBase.membership()
                .mapInternalServiceApiFailure()
                .flatMapAsync { membership in
                    switch self.authFlow {
                    case .registration:
                        return await self.executeSignUpFlowAsync(membershipUniqueId: membership.uniqueIdentifier, passwordData: passwordBytes!)
                    case .recovery:
                        return await self.executeRecoveryFlowAsync(membershipUniqueId: membership.uniqueIdentifier, passwordData: passwordBytes!)
                    }
                }
        } catch {
            return .failure(.internalServiceApi("Failed to get bytes from secure password"))
        }
    }
    
    private func executeSignUpFlowAsync(
        membershipUniqueId: Data,
        passwordData: Data
    ) async -> Result<Unit, InternalValidationFailure> {
        return await OpaqueProtocolService.createOprfRequest(password: passwordData)
            .mapOpaqueFailure()
            .flatMapAsync { oprfData in
                return await RequestPipeline.runAsync(
                    requestResult: RequestBuilder.buildRegistrationInitRequest(
                        oprfRequest: oprfData.oprfRequest,
                        verificationSessionId: membershipUniqueId
                    ),
                    pubKeyExchangeType: .dataCenterEphemeralConnect,
                    serviceType: .opaqueRegistrationInit,
                    flowType: .single,
                    cancellationToken: CancellationToken(),
                    networkProvider: self.networkProvider,
                    parseAndValidate: { (response: Ecliptix_Proto_Membership_OprfRegistrationInitResponse) in
                        guard response.result == .succeeded else {
                            return .failure(InternalValidationFailure.networkError(response.message))
                        }

                         return .success(response)
                    })
                   .MatchAsync(
                       onSuccessAsync: { response in
                           return await executeSignUpCompleteRequest(passwordData: passwordData, oprfData: oprfData, response: response)
                       },
                       onFailureAsync: { error in
                           return .failure(error)
                       }
                   )
            }
    }
    
    private func executeRecoveryFlowAsync(
        membershipUniqueId: Data,
        passwordData: Data
    ) async -> Result<Unit, InternalValidationFailure> {
        return await OpaqueProtocolService.createOprfRequest(password: passwordData)
            .mapOpaqueFailure()
            .flatMapAsync { oprfData in
                return await RequestPipeline.runAsync(
                    requestResult: RequestBuilder.buildRecoverySecureKeyInitRequest(
                        oprfRequest: oprfData.oprfRequest,
                        verificationSessionId: membershipUniqueId
                    ),
                    pubKeyExchangeType: .dataCenterEphemeralConnect,
                    serviceType: .opaqueRecoverySecretKeyInitRequest,
                    flowType: .single,
                    cancellationToken: CancellationToken(),
                    networkProvider: self.networkProvider,
                    parseAndValidate: { (response: Ecliptix_Proto_Membership_OprfRecoverySecureKeyInitResponse) in
                        guard response.result == .succeeded else {
                            return .failure(InternalValidationFailure.networkError(response.message))
                        }

                         return .success(response)
                    })
                   .MatchAsync(
                       onSuccessAsync: { response in
                           return await executeRecoveryCompleteRequest(passwordData: passwordData, response: response)
                       },
                       onFailureAsync: { error in
                           return .failure(error)
                       }
                   )
            }
    }
    
    private func executeSignUpCompleteRequest(
        passwordData: Data,
        oprfData: OprfData,
        response: Ecliptix_Proto_Membership_OprfRegistrationInitResponse
    ) async -> Result<Unit, InternalValidationFailure> {
       
        return await RequestPipeline.run(
           requestResult: RequestBuilder.buildRegistrationCompleteRequest(
               passwordData: passwordData,
               blind: oprfData.blind,
               response: response),
           pubKeyExchangeType: .dataCenterEphemeralConnect,
           serviceType: .opaqueRegistrationComplete,
           flowType: .single,
           cancellationToken: CancellationToken(),
           networkProvider: self.networkProvider,
           parseAndValidate: { (response: Ecliptix_Proto_Membership_OprfRegistrationCompleteResponse) in
               return .success(response)
           })
       .Match(onSuccess: { _ in
           return .success(.value)
       }, onFailure: { error in
           return .failure(error)
       })
    }
    
    private func executeRecoveryCompleteRequest(
        passwordData: Data,
        response: Ecliptix_Proto_Membership_OprfRecoverySecureKeyInitResponse
    ) async -> Result<Unit, InternalValidationFailure> {
       
        return await RequestPipeline.run(
           requestResult: RequestBuilder.buildRecoverySecureKeyCompleteRequest(
               passwordData: passwordData,
               response: response),
           pubKeyExchangeType: .dataCenterEphemeralConnect,
           serviceType: .opaqueRecoverySecretKeyCompleteRequest,
           flowType: .single,
           cancellationToken: CancellationToken(),
           networkProvider: self.networkProvider,
           parseAndValidate: { (response: Ecliptix_Proto_Membership_OprfRecoverySecretKeyCompleteResponse) in
               return .success(response)
           })
       .Match(onSuccess: { _ in
           return .success(.value)
       }, onFailure: { error in
           return .failure(error)
       })
    }
}
