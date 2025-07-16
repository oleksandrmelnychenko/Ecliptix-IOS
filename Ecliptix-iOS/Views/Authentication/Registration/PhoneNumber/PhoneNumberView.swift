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
        AuthScreenContainer(spacing: 24, content: {
            AuthViewHeader(
                viewTitle: String(localized: "Phone number"),
                viewDescription: String(localized: "Pleace confirm your country code and phone number")
            )
            
            FieldInput<PhoneValidationError, PhoneInputField>(
                title: String(localized: "Phone Number"),
                text: $viewModel.phoneNumber,
                hintText: String(localized: "Include country code"),
                validationErrors: viewModel.validationErrors,
                content: {
                    PhoneInputField(
                        phoneNumber: $viewModel.phoneNumber
                    )
                }
            )
            
            FormErrorText(error: viewModel.errorMessage)
            
            PrimaryActionButton(
                title: String(localized: "Continue"),
                isLoading: viewModel.isLoading,
                isEnabled: !viewModel.phoneNumber.isEmpty && !viewModel.isLoading,
                action: {
                    Task {
                        await viewModel.submitPhone()
                    }
                }
            )
            
            Spacer()
        })
    }
}


#Preview {
    let navService = NavigationService()
    return PhoneNumberView(navigation: navService, authFlow: .registration)
        .environmentObject(navService)
}
