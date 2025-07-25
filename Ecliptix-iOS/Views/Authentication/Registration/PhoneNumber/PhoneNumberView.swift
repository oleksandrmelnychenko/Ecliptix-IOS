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
                viewTitle: String(localized: "Phone number"),
                viewDescription: String(localized: "Please confirm your country code and phone number")
            )
            
            FieldInput<PhoneValidationError, PhoneInputField>(
                title: String(localized: "Phone Number"),
                text: $viewModel.phoneNumber,
                hintText: String(localized: "Include country code"),
                validationErrors: viewModel.validationErrors,
                showValidationErrors: self.$viewModel.showPhoneNumberValidationErrors,
                content: {
                    PhoneInputField(
                        phoneNumber: $viewModel.phoneNumber
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
                title: String(localized: "Continue"),
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
                    phoneNumber: viewModel.phoneNumber,
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
