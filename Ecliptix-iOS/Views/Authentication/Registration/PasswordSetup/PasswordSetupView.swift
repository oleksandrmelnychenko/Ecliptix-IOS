//
//  PasswordSetupView.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 20.05.2025.
//

import SwiftUI

struct PasswordSetupView: View {
    @EnvironmentObject private var navigation: NavigationService
    @EnvironmentObject private var localization: LocalizationService
    
    @StateObject private var viewModel: PasswordSetupViewModel
    @State private var showPassword = false
    
    init(verificationSessionId: Data, authFlow: AuthFlow) {
        _viewModel = StateObject(wrappedValue: PasswordSetupViewModel(
            verficationSessionId: verificationSessionId,
            authFlow: authFlow))
    }

    var body: some View {
        AuthScreenContainer(spacing: 24) {
            AuthViewHeader(
                viewTitle: String(localized: "Create a Password"),
                viewDescription: String(localized: "Make sure it’s secure and something you’ll remember.")
            )
            
            Group {
                FieldInput<PasswordValidationError, PasswordInputField>(
                    title: String(localized: "Password"),
                    text: $viewModel.password,
                    hintText: "8 Chars, 1 upper and 1 number",
                    validationErrors: viewModel.passwordValidationErrors,
                    showValidationErrors: self.$viewModel.showPasswordValidationErrors,
                    content: {
                        PasswordInputField(
                            placeholder: String(localized: "Secret Key"),
                            isNewPassword: true,
                            showPassword: $showPassword,
                            text: $viewModel.password,
                        )
                    }
                ).onChange(of: viewModel.password) { _, newPassword in
                    viewModel.updatePassword(passwordText: newPassword)
                }
                                    
                FieldInput<PasswordValidationError, PasswordInputField>(
                    title: String(localized: "Confirm Password"),
                    text: $viewModel.confirmPassword,
                    hintText: "8 Chars, 1 upper and 1 number",
                    validationErrors: viewModel.confirmPasswordValidationErrors,
                    showValidationErrors: self.$viewModel.showConfirmationPasswordValidationErrors,
                    content: {
                        PasswordInputField(
                            placeholder: String(localized: "Confirm Secret Key"),
                            isNewPassword: true,
                            showPassword: $showPassword,
                            text: $viewModel.confirmPassword,
                        )
                    }
                ).onChange(of: viewModel.confirmPassword) { _, newConfirmPassword in
                    viewModel.updateConfirmPassword(passwordText: newConfirmPassword)
                }
            }
            
            FormErrorText(error: viewModel.errorMessage)
            
            PrimaryButton(
                title: String(localized: "Next"),
                isEnabled: (viewModel.isFormValid && !viewModel.isLoading),
                isLoading: viewModel.isLoading,
                style: .dark,
                action: {
                    Task {
                        await viewModel.submitPassword()
                    }
                }
            )
            
            Spacer()
        }
        .onChange(of: viewModel.shouldNavigateToPassPhase) { _, shouldNavigate in
            if shouldNavigate {
                navigation.navigate(to: .passPhaseRegistration)
                
                DispatchQueue.main.async {
                    viewModel.shouldNavigateToPassPhase = false
                }
            }
        }
    }
}

#Preview {
    let navService = NavigationService()
    let localService = LocalizationService.shared
    
    PasswordSetupView(
        verificationSessionId: Data(),
        authFlow: .registration)
    .environmentObject(navService)
    .environmentObject(localService)
}
