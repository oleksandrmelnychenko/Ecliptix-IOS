//
//  PasswordSetupView.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 20.05.2025.
//

import SwiftUI

struct PasswordSetupView: View {
    @StateObject private var viewModel: PasswordSetupViewModel
    
    init(navigation: NavigationService) {
        _viewModel = StateObject(wrappedValue: PasswordSetupViewModel(navigation: navigation))
    }

    var body: some View {
        AuthScreenContainer(spacing: 24, content: {
            AuthViewHeader(
                viewTitle: Strings.PasswordSetup.title,
                viewDescription: Strings.PasswordSetup.description
            )
            
            Group {
                // Password field
                PasswordFieldView(
                    title: Strings.PasswordSetup.passwordFieldLabel,
                    text: $viewModel.password,
                    placeholder: Strings.PasswordSetup.passwordFieldPlaceholder,
                    validationErrors: viewModel.validationErrors
                )
                                    
                // Confirm password field
                PasswordFieldView(
                    title: Strings.PasswordSetup.confirmPasswordFieldLabel,
                    text: $viewModel.confirmPassword,
                    placeholder: Strings.PasswordSetup.confirmPasswordFieldPlaceholder,
                    validationErrors: viewModel.confirmPasswordValidationError
                )
            }
            
            FormErrorText(error: viewModel.errorMessage)
            
            PrimaryActionButton(
                title: Strings.PasswordSetup.Buttons.next,
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.isFormValid && !viewModel.isLoading,
                action: viewModel.submitPassword
            )
            
            Spacer()
        })
    }
}

#Preview {
    let navService = NavigationService()
    return PasswordSetupView(navigation: navService)
        .environmentObject(navService)
}
