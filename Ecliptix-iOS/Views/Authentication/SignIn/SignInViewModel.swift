//
//  SignInViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.06.2025.
//

import Foundation
import SwiftUI

@MainActor
final class SignInViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var password: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showPasswordValidationErrors: Bool = false
    @Published var showPhoneNumberErrors: Bool = false
    
    @Published var shouldNavigateToMainApp: Bool = false
    @Published var shouldNavigateToRecoveryPassword: Bool = false
    
    private let networkController: NetworkProvider
    private let phoneValidator = PhoneValidator()
    private let passwordValidator = PasswordValidator()
    
    private var securePasswordHandle: SodiumSecureMemoryHandle?
    
    var phoneValidationErrors: [PhoneValidationError] {
        phoneValidator.validate(phoneNumber)
    }
    
    var passwordValidationErrors: [PasswordValidationError] {
        passwordValidator.validate(password)
    }
    
    var isFormValid: Bool {
        passwordValidationErrors.isEmpty &&
        phoneValidationErrors.isEmpty &&
        !password.isEmpty &&
        !phoneNumber.isEmpty
    }
    
    init() {
        self.networkController = try! ServiceLocator.shared.resolve(NetworkProvider.self)
    }
    
    func signInButton() async {
        guard isFormValid else { return }

        await self.submitRegistrationPassword()
    }
    
    func forgotPasswordTapped() {
        self.shouldNavigateToRecoveryPassword = true
    }
    
    func updatePassword(passwordText: String?) {
        securePasswordHandle?.dispose()
        securePasswordHandle = nil

        self.showPasswordValidationErrors = true
        
        do {
            if passwordText != nil && !passwordText!.isEmpty {
                let result = Self.convertStringToSodiumHandle(text: passwordText!)
                if result.isOk {
                    securePasswordHandle = try result.unwrap()
                } else {
                    securePasswordHandle = nil
                    errorMessage = "Error processing password: \(try result.unwrapErr().message)"
                }
            }
        } catch {
            
        }
    }
    
    private static func convertStringToSodiumHandle(text: String) -> Result<SodiumSecureMemoryHandle, EcliptixProtocolFailure> {
        guard !text.isEmpty else {
            return SodiumSecureMemoryHandle.allocate(length: 0).mapSodiumFailure()
        }

        guard let utf8Data = text.data(using: .utf8) else {
            return .failure(.decode("Failed to encode password string to UTF-8 bytes."))
        }

        var rentedBuffer: Data? = utf8Data
        defer {
            rentedBuffer?.resetBytes(in: 0..<utf8Data.count)
            rentedBuffer?.removeAll()
        }

        do {
            let handle = try SodiumSecureMemoryHandle.allocate(length: utf8Data.count).unwrap()
            let writeResult = rentedBuffer!.withUnsafeBytes { ptr in
                handle.write(data: ptr).mapSodiumFailure()
            }

            guard writeResult.isOk else {
                handle.dispose()
                return .failure(try writeResult.unwrapErr())
            }

            return .success(handle)
        } catch {
            return .failure(.generic("Failed to convert string to secure handle.", inner: error))
        }
    }
    
    private func submitRegistrationPassword() async {
        guard let securePasswordHandle = self.securePasswordHandle else {
            errorMessage = "Failed to obtain secure password handle."
            return
        }
        
        guard !securePasswordHandle.isInvalid else {
            errorMessage = "Password is required."
            return
        }
        
        let result = getPasswordData(securePasswordHandle: securePasswordHandle)
            .flatMap { passwordData in
                OpaqueProtocolService.createOprfRequest(password: passwordData)
                    .mapError { .internalServiceApi("Failed to create OPRF request", inner: $0) }
                    .map { oprfData in (passwordData, oprfData) }
            }
        
        await result.MatchAsync(
            onSuccessAsync: { (passwordData, oprfData) in
                _ = await RequestPipeline.runAsync(
                    requestResult: RequestBuilder.buildSignInInitRequest(
                        passwordData: passwordData,
                        oprfRequest: oprfData.oprfRequest,
                        phoneNumber: self.phoneNumber),
                    pubKeyExchangeType: .dataCenterEphemeralConnect,
                    serviceType: .opaqueSignInInitRequest,
                    flowType: .single,
                    cancellationToken: CancellationToken(),
                    networkProvider: self.networkController,
                    parseAndValidate: { (response: Ecliptix_Proto_Membership_OpaqueSignInInitResponse) in
                        guard response.result == .succeeded else {
                            return .failure(InternalValidationFailure.networkError(response.message))
                        }
                                        
                        return .success(response)
                    })
                .MatchAsync(
                    onSuccessAsync: { response in
                    
                        let serverPublicKeyResult = ViewModelBase.serverPublicKey(networkProvider: self.networkController)
                            .mapInternalServiceApiFailure()

                        let finalizationResult = serverPublicKeyResult.flatMap { serverPubKey in
                                let opaqueService = OpaqueProtocolService(staticPublicKey: serverPubKey)

                                return opaqueService.createSignInFinalizationRequest(
                                    phoneNumber: self.phoneNumber,
                                    password: passwordData,
                                    response: response,
                                    blind: oprfData.blind
                                )
                                .mapOpaqueFailure()
                                .map { context in (opaqueService, context) }
                            }

                        await finalizationResult.MatchAsync(
                            onSuccessAsync: { (opaqueService, context) in
                                await RequestPipeline.runAsync(
                                    requestResult: RequestBuilder.buildSignInCompleteRequest(
                                        phoneNumber: self.phoneNumber,
                                        clientEphemeralPublicKey: context.clientEphemeralPublicKey,
                                        clientMacKey: context.sessionKeys.clientMacKey,
                                        transcriptHash: context.transcriptHash,
                                        response: response
                                    ),
                                    pubKeyExchangeType: .dataCenterEphemeralConnect,
                                    serviceType: .opaqueSignInCompleteRequest,
                                    flowType: .single,
                                    cancellationToken: CancellationToken(),
                                    networkProvider: self.networkController,
                                    parseAndValidate: { (response: Ecliptix_Proto_Membership_OpaqueSignInFinalizeResponse) in
                                        guard response.result == .succeeded else {
                                            return .failure(.networkError(response.message))
                                        }
                                        return .success(response)
                                    }
                                ).Match(
                                    onSuccess: { finalizeResponse in
                                        let verificationResult = opaqueService.verifyServerMacAndGetSessionKey(
                                            response: finalizeResponse,
                                            sessionKey: context.sessionKeys.sessionKey,
                                            serverMacKey: context.sessionKeys.serverMacKey,
                                            transcriptHash: context.transcriptHash
                                        )

                                        switch verificationResult {
                                        case .success:
                                            self.shouldNavigateToMainApp = true
                                        case .failure(let failure):
                                            self.errorMessage = failure.message
                                        }
                                    },
                                    onFailure: { error in
                                        self.errorMessage = error.message
                                    }
                                )
                            },
                            onFailureAsync: { error in
                                self.errorMessage = error.message
                            }
                        )
                }, onFailureAsync: { error in
                    self.errorMessage = error.message
                })
        },
            onFailureAsync: { error in
                self.errorMessage = error.message
        })
    }

    private func getPasswordData(
        securePasswordHandle: SodiumSecureMemoryHandle
    ) -> Result<Data, InternalValidationFailure> {
        var rentedPasswordBytes: Data? = Data(count: securePasswordHandle.length)

        defer {
            if var bytes = rentedPasswordBytes {
                bytes.resetBytes(in: 0..<bytes.count)
                bytes.removeAll()
                rentedPasswordBytes = nil
            }
        }
        
        return Result<Data, InternalValidationFailure>.Try({
            _ = try rentedPasswordBytes!.withUnsafeMutableBytes { destPtr in
                try securePasswordHandle
                    .read(into: destPtr)
                    .mapSodiumFailure()
                    .mapEcliptixProtocolFailure()
                    .mapNetworkFailure()
                    .unwrap()
            }
            return rentedPasswordBytes!
        }, errorMapper: { error in
            if let mapped = error as? InternalValidationFailure {
                return mapped
            } else {
                return .internalServiceApi("Failed to read password from secure memory", inner: error)
            }
        })
    }
}
