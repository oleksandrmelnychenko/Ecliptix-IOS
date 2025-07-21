//
//  PhoneNumberView.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 20.05.2025.
//

import SwiftUI

struct PhoneNumberView: View {
    @StateObject private var viewModel: PhoneNumberViewModel
    
    init(navigation: NavigationService, authFlow: AuthFlow) {
        _viewModel = StateObject(wrappedValue: PhoneNumberViewModel(
            navigation: navigation,
            authFlow: authFlow))
    }

    var body: some View {
        AuthScreenContainer(spacing: 24, canGoBack: self.viewModel.navigation.canGoBack()) {
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
    }
}


#Preview {
    let navService = NavigationService()
    return PhoneNumberView(navigation: navService, authFlow: .registration)
}
