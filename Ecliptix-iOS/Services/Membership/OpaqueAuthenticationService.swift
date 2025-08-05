//
//  OpaqueAuthenticationService.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 31.07.2025.
//

import Foundation

struct OpaqueAuthenticationService {
    private let networkProvider: NetworkProvider
    
    init(networkProvider: NetworkProvider) {
        self.networkProvider = networkProvider
    }
    
    func signInAsync(
        mobileNumber: String,
        securePassword: SecureTextBuffer
    ) async -> Result<Data, InternalValidationFailure> {
        do {
            
            var passwordBytes: Data?
            try securePassword.withSecureBytes { bytes in
                passwordBytes = bytes
            }
            if passwordBytes == nil || passwordBytes!.isEmpty {
                return .failure(.invalidValue(Strings.ValidationErrors.SecureKey.required))
            }
            
            return await self.executeSignInFlowAsync(mobileNumber: mobileNumber, passwordData: passwordBytes!)
        } catch {
            return .failure(.internalServiceApi("Failed to get bytes from secure password"))
        }
    }
    
    private func executeSignInFlowAsync(
        mobileNumber: String,
        passwordData: Data
    ) async -> Result<Data, InternalValidationFailure> {
        return await createOpaqueService()
            .flatMapAsync { opaqueService in
                await OpaqueProtocolService.createOprfRequest(password: passwordData).mapOpaqueFailure()
                    .flatMapAsync { oprfData in
                        return await RequestPipeline.runAsync(
                            requestResult: RequestBuilder.buildSignInInitRequest(
                                passwordData: passwordData,
                                oprfRequest: oprfData.oprfRequest,
                                phoneNumber: mobileNumber),
                            pubKeyExchangeType: .dataCenterEphemeralConnect,
                            serviceType: .opaqueSignInInitRequest,
                            flowType: .single,
                            cancellationToken: CancellationToken(),
                            networkProvider: networkProvider,
                            parseAndValidate: { (response: Ecliptix_Proto_Membership_OpaqueSignInInitResponse) in
                                guard response.result == .succeeded else {
                                    return .failure(InternalValidationFailure.networkError(response.message))
                                }
                                                
                                return .success(response)
                            })
                        .MatchAsync(
                            onSuccessAsync: { response in
                                return await opaqueService.createSignInFinalizationRequest(
                                        phoneNumber: mobileNumber,
                                        password: passwordData,
                                        response: response,
                                        blind: oprfData.blind
                                    )
                                .mapOpaqueFailure()
                                .flatMapAsync { context in
                                    await executeSignInFinalizationRequest(
                                        mobileNumber: mobileNumber,
                                        opaqueService: opaqueService,
                                        context: context,
                                        response: response)
                                }
                        }, onFailureAsync: { error in
                            return .failure(error)
                        })
                    }
            }
    }
    
    private func executeSignInFinalizationRequest(
        mobileNumber: String,
        opaqueService: OpaqueProtocolService,
        context: SignInFinalizationContext,
        response: Ecliptix_Proto_Membership_OpaqueSignInInitResponse
    ) async -> Result<Data, InternalValidationFailure> {
        
        return await RequestPipeline.runAsync(
            requestResult: RequestBuilder.buildSignInCompleteRequest(
                phoneNumber: mobileNumber,
                clientEphemeralPublicKey: context.clientEphemeralPublicKey,
                clientMacKey: context.sessionKeys.clientMacKey,
                transcriptHash: context.transcriptHash,
                response: response
            ),
            pubKeyExchangeType: .dataCenterEphemeralConnect,
            serviceType: .opaqueSignInCompleteRequest,
            flowType: .single,
            cancellationToken: CancellationToken(),
            networkProvider: networkProvider,
            parseAndValidate: { (response: Ecliptix_Proto_Membership_OpaqueSignInFinalizeResponse) in
                guard response.result == .succeeded else {
                    return .failure(.networkError(response.message))
                }
                return .success(response)
            }
        )
        .Match(
            onSuccess: { finalizeResponse in
                let verificationResult = opaqueService.verifyServerMacAndGetSessionKey(
                    response: finalizeResponse,
                    sessionKey: context.sessionKeys.sessionKey,
                    serverMacKey: context.sessionKeys.serverMacKey,
                    transcriptHash: context.transcriptHash
                )

                return verificationResult.mapOpaqueFailure()
            },
            onFailure: { error in
                return .failure(error)
            }
        )
    }
    
    private func createOpaqueService() -> Result<OpaqueProtocolService, InternalValidationFailure> {
        return ViewModelBase.serverPublicKey()
            .mapInternalServiceApiFailure()
            .map { serverPubKey in
                OpaqueProtocolService(staticPublicKey: serverPubKey)
            }
    }
}
