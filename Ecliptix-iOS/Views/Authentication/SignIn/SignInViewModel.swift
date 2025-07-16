//
//  SignInViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.06.2025.
//

import Foundation

@MainActor
final class SignInViewModel: ObservableObject {
    @Published var phoneNumber: String = "970177981"
    @Published var phoneCode: String = "+380"
    @Published var password: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let navigation: NavigationService
    private let networkController: NetworkProvider
    private let phoneValidator = PhoneValidator()
    private let passwordValidator = PasswordValidator()
    
    private var securePasswordHandle: SodiumSecureMemoryHandle?
    
    var fullPhoneNumber: String {
        return phoneCode + phoneNumber
    }
    
    var phoneValidationErrors: [PhoneValidationError] {
        phoneValidator.validate(fullPhoneNumber)
    }
    
    var passwordValidationErrors: [PasswordValidationError] {
        passwordValidator.validate(password)
    }
    
    var isFormValid: Bool {
        passwordValidationErrors.isEmpty &&
        phoneValidationErrors.isEmpty &&
        !password.isEmpty &&
        !fullPhoneNumber.isEmpty
    }
    
    init(navigation: NavigationService) {
        self.navigation = navigation
        self.networkController = ServiceLocator.shared.resolve(NetworkProvider.self)
    }
    
    func signInButton() async {
        guard isFormValid else { return }

        await self.submitRegistrationPassword()
    }
    
    func updatePassword(passwordText: String?) {
        securePasswordHandle?.dispose()
        securePasswordHandle = nil

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
        if self.securePasswordHandle == nil || self.securePasswordHandle!.isInvalid {
            errorMessage = "Password is required."
            return
        }

        await MainActor.run {
            self.errorMessage = nil
            self.isLoading = true
        }

        do {
            let passwordLength = self.securePasswordHandle!.length
            var passwordBytes = Data(count: passwordLength)

            let readResult = passwordBytes.withUnsafeMutableBytes { bufferPointer in
                self.securePasswordHandle!.read(into: bufferPointer).mapSodiumFailure()
            }
            if readResult.isErr {
                errorMessage = try readResult.unwrapErr().message
                return
            }

            let serverStaticPublicKey = await ViewModelBase.serverPublicKey()
            let clientOpaqueService = OpaqueProtocolService(staticPublicKey: serverStaticPublicKey)

            let oprfResult = OpaqueProtocolService.createOprfRequest(password: passwordBytes)
            if oprfResult.isErr {
                errorMessage = "Failed to create OPAQUE request: \(try oprfResult.unwrapErr().message)"
                return
            }

            let oprfRequest = try oprfResult.unwrap().oprfRequest
            let blind = try oprfResult.unwrap().blind

            var initRequest = Ecliptix_Proto_Membership_OpaqueSignInInitRequest()
            initRequest.phoneNumber = fullPhoneNumber
            initRequest.peerOprf = oprfRequest

            let connectId = ViewModelBase.computeConnectId(pubKeyExchangeType: .dataCenterEphemeralConnect)

            let overrallResult = try await self.networkController.executeServiceAction(
                connectId: connectId,
                serviceType: .opaqueSignInInitRequest,
                plainBuffer: try initRequest.serializedData(),
                flowType: .single,
                onSuccessCallback: { payload in
                    do {
                        let initResponse = try Helpers.parseFromBytes(Ecliptix_Proto_Membership_OpaqueSignInInitResponse.self, data: payload)

                        let finalizationResult = clientOpaqueService.createSignInFinalizationRequest(
                            phoneNumber: self.fullPhoneNumber,
                            password: passwordBytes,
                            response: initResponse,
                            blind: blind
                        )

                        if finalizationResult.isErr {
                            let failure = NetworkFailure.unexpectedError("Failed to process server response: \(try finalizationResult.unwrapErr().message)")
                            self.errorMessage = failure.message
                            return .failure(failure)
                        }

                        let finalizeRequest = try finalizationResult.unwrap().0
                        let sessionKey = try finalizationResult.unwrap().1
                        let serverMacKey = try finalizationResult.unwrap().2
                        let transcriptHash = try finalizationResult.unwrap().3

                        let connectId = ViewModelBase.computeConnectId(pubKeyExchangeType: .dataCenterEphemeralConnect)

                        return try await self.networkController.executeServiceAction(
                            connectId: connectId,
                            serviceType: .opaqueSignInCompleteRequest,
                            plainBuffer: try finalizeRequest.serializedData(),
                            flowType: .single,
                            onSuccessCallback: { payload2 in
                                do {
                                    let finalizeResponse = try Helpers.parseFromBytes(Ecliptix_Proto_Membership_OpaqueSignInFinalizeResponse.self, data: payload2)

                                    if finalizeResponse.result == .invalidCredentials {
                                        self.errorMessage = finalizeResponse.message.isEmpty ? "Invalid credentials." : finalizeResponse.message
                                        return .failure(.unexpectedError("Invalid credentials."))
                                    }

                                    let verificationResult = clientOpaqueService.verifyServerMacAndGetSessionKey(
                                        response: finalizeResponse,
                                        sessionKey: sessionKey,
                                        serverMacKey: serverMacKey,
                                        transcriptHash: transcriptHash)

                                    if verificationResult.isErr {
                                        let failure = NetworkFailure.unexpectedError("Server authentication failed: \(try verificationResult.unwrapErr().message)")
                                        self.errorMessage = failure.message
                                        return .failure(failure)
                                    }

                                    let finalSessionKey = try verificationResult.unwrap()
                                    self.navigation.navigate(to: .passPhaseLogin)

                                    return .success(.value)
                                } catch {
                                    self.errorMessage = "Unexpected error during finalization: \(error.localizedDescription)"
                                    self.isLoading = false
                                    return .failure(.unexpectedError("Unexpected error"))
                                }
                            })
                    } catch {
                        self.errorMessage = "Unexpected error during sign-in: \(error.localizedDescription)"
                        return .failure(.unexpectedError("Unexpected error"))
                    }
                })

            if overrallResult.isErr {
                self.errorMessage = "Sign-in network request failed: \(try overrallResult.unwrapErr().message)"
                self.isLoading = false
            }

        } catch {
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            self.isLoading = false
        }
    }

}
