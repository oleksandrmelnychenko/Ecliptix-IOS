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
    
    @Published var shouldNavigateToCodeVerification: Bool = false
    @Published var phoneNumberIdentifier: Data?
    @Published var authFlow: AuthFlow
    
    private let phoneValidator = PhoneValidator()
    private let networkController: NetworkProvider
    
    private var validatePhoneNumberResponce: Ecliptix_Proto_Membership_ValidatePhoneNumberResponse? = nil
    
    private func validatePhoneNumber() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.validationErrors = self.phoneValidator.validate(self.phoneNumber)
        }
    }
    
    init(authFlow: AuthFlow) {
        self.networkController = try! ServiceLocator.shared.resolve(NetworkProvider.self)
        
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
        _ = await RequestPipeline.run(
            requestResult: RequestBuilder.buildValidationPhoneNumberRequest(
                networkProvider: networkController,
                phoneNumber: phoneNumber),
            pubKeyExchangeType: .dataCenterEphemeralConnect,
            serviceType: .validatePhoneNumber,
            flowType: .single,
            cancellationToken: CancellationToken(),
            networkProvider: self.networkController,
            parseAndValidate: { (response: Ecliptix_Proto_Membership_ValidatePhoneNumberResponse) in
                                
                guard response.result == .succeeded else {
                    return .failure(.networkError(response.message))
                }
                
                return .success(response)
            }
        )
        .Match(
            onSuccess: { response in
                self.shouldNavigateToCodeVerification = true
                self.phoneNumberIdentifier = response.phoneNumberIdentifier
        }, onFailure: { error in
            self.errorMessage = error.message

        })
    }

    
    private func recoveryPhoneNumber(phoneNumber: String) async {
        _ = await RequestPipeline.run(
            requestResult: RequestBuilder.buildValidationPhoneNumberRequest(
                networkProvider: networkController,
                phoneNumber: phoneNumber),
            pubKeyExchangeType: .dataCenterEphemeralConnect,
            serviceType: .recoverySecretKeyPhoneVerification,
            flowType: .single,
            cancellationToken: CancellationToken(),
            networkProvider: self.networkController,
            parseAndValidate: { (response: Ecliptix_Proto_Membership_ValidatePhoneNumberResponse) in
                                
                guard response.result == .succeeded else {
                    return .failure(.networkError(response.message))
                }
                
                return .success(response)
            }
        )
        .Match(
            onSuccess: { response in
                self.shouldNavigateToCodeVerification = true
                self.phoneNumberIdentifier = response.phoneNumberIdentifier
        }, onFailure: { error in
            self.errorMessage = error.message

        })
    }
}
