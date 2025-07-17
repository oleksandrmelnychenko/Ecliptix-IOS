//
//  PhoneNumberViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import Foundation

@MainActor
final class PhoneNumberViewModel: ObservableObject {
    @Published var phoneNumber: String = "+380970177999" {
        didSet {
            validatePhoneNumber()
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var validationErrors: [PhoneValidationError] = []
    @Published var showPhoneNumberValidationErrors: Bool = false

    private let navigation: NavigationService
    private let phoneValidator = PhoneValidator()
    private let networkController: NetworkProvider
    
    private var validatePhoneNumberResponce: Ecliptix_Proto_Membership_ValidatePhoneNumberResponse? = nil
    
    private func validatePhoneNumber() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.validationErrors = self.phoneValidator.validate(self.phoneNumber)
        }
    }
    
    private let authFlow: AuthFlow
    
    init(navigation: NavigationService, authFlow: AuthFlow) {
        self.navigation = navigation
        
        self.networkController = ServiceLocator.shared.resolve(NetworkProvider.self)
        
        self.authFlow = authFlow
    }

    func submitPhone() async {
        guard !phoneNumber.isEmpty else { return }

        errorMessage = nil
        isLoading = true

        switch authFlow {
        case .registration:
            await self.validatePhoneNumber(phoneNumber: self.phoneNumber)
        case .recovery:
            await self.recoveryPhoneNumber(phoneNumber: self.phoneNumber)
        }
        
        
        isLoading = false
    }
    
    private func validatePhoneNumber(phoneNumber: String) async {
        let cancellationToken = CancellationToken()

        guard let systemDeviceIdentifier = ViewModelBase.systemDeviceIdentifier() else {
            errorMessage = "Invalid device ID"
            return
        }

        guard UUID(uuidString: phoneNumber) == nil else {
            errorMessage = "Phone number must not be a GUID"
            return
        }
        
        guard let uuid = UUID(uuidString: systemDeviceIdentifier) else {
            errorMessage = "Invalid UUID format"
            return
        }
        
        let deviceIdData = withUnsafeBytes(of: uuid.uuid) { Data($0) }

        var request = Ecliptix_Proto_Membership_ValidatePhoneNumberRequest()
        request.phoneNumber = phoneNumber
        request.appDeviceIdentifier = deviceIdData

        let connectId = ViewModelBase.computeConnectId(pubKeyExchangeType: .dataCenterEphemeralConnect)

        do {
            let validatePhoneNumberResult = try await self.networkController.executeServiceAction(
                connectId: connectId,
                serviceType: .validatePhoneNumber,
                plainBuffer: try request.serializedData(),
                flowType: .single,
                onSuccessCallback: { [weak self] payload in
                    guard let self else {
                        return .failure(.unexpectedError("Self is nil"))
                    }

                    do {
                        self.validatePhoneNumberResponce = try Helpers.parseFromBytes(
                            Ecliptix_Proto_Membership_ValidatePhoneNumberResponse.self,
                            data: payload
                        )

                        if self.validatePhoneNumberResponce!.result == .invalidPhone {
                            return .failure(.serverErrrorResponse(self.validatePhoneNumberResponce!.message))
                        }
                        
                        return .success(.value)
                    } catch {
                        return .failure(.unexpectedError("Failed to parse validation response", inner: error))
                    }
                },
                token: cancellationToken
            )
            
            
            if validatePhoneNumberResult.isErr {
                self.errorMessage = try validatePhoneNumberResult.unwrapErr().message
            } else {
                self.navigation.navigate(to: .verificationCode(phoneNumber: self.phoneNumber, phoneNumberIdentifier: self.validatePhoneNumberResponce!.phoneNumberIdentifier, authFlow: self.authFlow))
            }
        } catch {
            self.errorMessage = "Network error during validation"
        }
    }
    
    private func recoveryPhoneNumber(phoneNumber: String) async {
        let cancellationToken = CancellationToken()

        guard let systemDeviceIdentifier = ViewModelBase.systemDeviceIdentifier() else {
            errorMessage = "Invalid device ID"
            return
        }

        guard UUID(uuidString: phoneNumber) == nil else {
            errorMessage = "Phone number must not be a GUID"
            return
        }
        
        guard let uuid = UUID(uuidString: systemDeviceIdentifier) else {
            errorMessage = "Invalid UUID format"
            return
        }
        
        let deviceIdData = withUnsafeBytes(of: uuid.uuid) { Data($0) }

        var request = Ecliptix_Proto_Membership_ValidatePhoneNumberRequest()
        request.phoneNumber = phoneNumber
        request.appDeviceIdentifier = deviceIdData

        let connectId = ViewModelBase.computeConnectId(pubKeyExchangeType: .dataCenterEphemeralConnect)

        do {
            let validatePhoneNumberResult = try await self.networkController.executeServiceAction(
                connectId: connectId,
                serviceType: .recoverySecretKeyPhoneVerification,
                plainBuffer: try request.serializedData(),
                flowType: .single,
                onSuccessCallback: { [weak self] payload in
                    guard let self else {
                        return .failure(.unexpectedError("Self is nil"))
                    }

                    do {
                        self.validatePhoneNumberResponce = try Helpers.parseFromBytes(
                            Ecliptix_Proto_Membership_ValidatePhoneNumberResponse.self,
                            data: payload
                        )

                        if self.validatePhoneNumberResponce!.result == .invalidPhone {
                            return .failure(.serverErrrorResponse(self.validatePhoneNumberResponce!.message))
                        }
                        
                        return .success(.value)
                    } catch {
                        return .failure(.unexpectedError("Failed to parse validation response", inner: error))
                    }
                },
                token: cancellationToken
            )
            
            
            if validatePhoneNumberResult.isErr {
                self.errorMessage = try validatePhoneNumberResult.unwrapErr().message
            } else {
                self.navigation.navigate(to: .verificationCode(phoneNumber: self.phoneNumber, phoneNumberIdentifier: self.validatePhoneNumberResponce!.phoneNumberIdentifier, authFlow: self.authFlow))
            }
        } catch {
            self.errorMessage = "Network error during validation"
        }
    }
}
