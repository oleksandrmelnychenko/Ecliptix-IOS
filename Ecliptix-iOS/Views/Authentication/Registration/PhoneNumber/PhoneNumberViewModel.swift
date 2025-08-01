//
//  PhoneNumberViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import Foundation

@MainActor
final class PhoneNumberViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showPhoneNumberValidationErrors: Bool = false
    
    @Published var shouldNavigateToCodeVerification: Bool = false
    @Published var phoneNumberIdentifier: Data?
    @Published var authFlow: AuthFlow
    
    private let phoneValidator = PhoneValidator()
    private let networkController: NetworkProvider
    
    private var validatePhoneNumberResponce: Ecliptix_Proto_Membership_ValidatePhoneNumberResponse? = nil
    
    var phoneValidationErrors: [PhoneValidationError] {
        phoneValidator.validate(phoneNumber).errors
    }
    
    var isFormValid: Bool {
        phoneValidationErrors.isEmpty &&
        !phoneNumber.isEmpty
    }
    
    init(authFlow: AuthFlow) {
        self.networkController = try! ServiceLocator.shared.resolve(NetworkProvider.self)
        
        self.authFlow = authFlow
    }

    func submitPhone() async {
        guard !phoneNumber.isEmpty else { return }

        errorMessage = nil
        isLoading = true

        let serviceType: RpcServiceType = switch authFlow {
        case .registration:
            .validatePhoneNumber
        case .recovery:
            .recoverySecretKeyPhoneVerification
        }
        
        await handlePhoneNumberSubmission(serviceType: serviceType)

        isLoading = false
    }
    
    private func handlePhoneNumberSubmission(serviceType: RpcServiceType) async {
        await RequestPipeline.run(
            requestResult: RequestBuilder.buildValidationPhoneNumberRequest(
                networkProvider: networkController,
                phoneNumber: phoneNumber),
            pubKeyExchangeType: .dataCenterEphemeralConnect,
            serviceType: serviceType,
            flowType: .single,
            cancellationToken: CancellationToken(),
            networkProvider: networkController,
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
            },
            onFailure: { error in
                self.errorMessage = error.message
            }
        )
    }
}
