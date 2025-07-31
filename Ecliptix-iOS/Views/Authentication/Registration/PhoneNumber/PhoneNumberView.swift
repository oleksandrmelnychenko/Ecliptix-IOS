//
//  PhoneNumberView.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 20.05.2025.
//

import SwiftUI

struct PhoneNumberView: View {
    @EnvironmentObject private var navigation: NavigationService
    @EnvironmentObject private var localization: LocalizationService
    
    @StateObject private var viewModel: PhoneNumberViewModel
    
    init(authFlow: AuthFlow) {
        _viewModel = StateObject(wrappedValue: PhoneNumberViewModel(authFlow: authFlow))
    }

    var body: some View {
        AuthScreenContainer(spacing: 24, canGoBack: self.navigation.canGoBack()) {
            AuthViewHeader(
                viewTitle: Strings.Authentication.SignUp.PhoneVerification.title,
                viewDescription: Strings.Authentication.SignUp.PhoneVerification.description
            )
            
            FieldInput<PhoneValidationError, PhoneInputField>(
                title: String(localized: "Phone Number"),
                hintText: Strings.Authentication.SignUp.PhoneVerification.mobileHint,
                validationErrors: viewModel.validationErrors,
                showValidationErrors: self.$viewModel.showPhoneNumberValidationErrors,
                content: {
                    PhoneInputField(
                        phoneNumber: $viewModel.phoneNumber, 
                        placeholder: Strings.Authentication.SignUp.PhoneVerification.mobilePlaceholder
                    )
                }
            )
            .onChange(of: viewModel.phoneNumber) { _, _ in
                if !self.viewModel.showPhoneNumberValidationErrors {
                    self.viewModel.showPhoneNumberValidationErrors = true
                }
            }
            
            FormErrorText(error: viewModel.errorMessage)
            
            PrimaryButton(
                title: Strings.Authentication.SignUp.PhoneVerification.continueButton,
                isEnabled: !viewModel.phoneNumber.isEmpty && !viewModel.isLoading,
                isLoading: viewModel.isLoading,
                style: .dark,
                action: {
                    Task {
                        await viewModel.submitPhone()
                    }
                }
            )
        }
        .onChange(of: viewModel.shouldNavigateToCodeVerification) { _, shouldNavigate in
            if shouldNavigate,
               let identifier = viewModel.phoneNumberIdentifier {
                navigation.navigate(to: .verificationCode(
                    phoneNumberIdentifier: identifier,
                    authFlow: viewModel.authFlow
                ))
                
                DispatchQueue.main.async {
                    viewModel.shouldNavigateToCodeVerification = false
                }
            }
        }
    }
}


#Preview {
    let navService = NavigationService()
    let localService = LocalizationService.shared
    PhoneNumberView(authFlow: .registration)
        .environmentObject(navService)
        .environmentObject(localService)
}
