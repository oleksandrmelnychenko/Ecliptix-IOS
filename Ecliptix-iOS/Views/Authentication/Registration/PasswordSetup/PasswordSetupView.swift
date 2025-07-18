//
//  PasswordSetupView.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 20.05.2025.
//

import SwiftUI

struct PasswordSetupView: View {
    @StateObject private var viewModel: PasswordSetupViewModel
    @State private var showPassword = false
    
    init(navigation: NavigationService, verificationSessionId: Data, authFlow: AuthFlow) {
        _viewModel = StateObject(wrappedValue: PasswordSetupViewModel(
            navigation: navigation,
            verficationSessionId: verificationSessionId,
            authFlow: authFlow))
    }

    var body: some View {
        AuthScreenContainer(spacing: 24, content: {
            AuthViewHeader(
                viewTitle: Strings.PasswordSetup.title,
                viewDescription: Strings.PasswordSetup.description
            )
            
            Group {
                FieldInput<PasswordValidationError, PasswordInputField>(
                    title: Strings.PasswordSetup.passwordFieldLabel,
                    text: $viewModel.password,
                    hintText: "8 Chars, 1 upper and 1 number",
                    validationErrors: viewModel.passwordValidationErrors,
                    showValidationErrors: self.$viewModel.showPasswordValidationErrors,
                    content: {
                        PasswordInputField(
                            placeholder: Strings.PasswordSetup.passwordFieldPlaceholder,
                            isNewPassword: true,
                            showPassword: $showPassword,
                            text: $viewModel.password,
                        )
                    }
                ).onChange(of: viewModel.password) { _, newPassword in
                    viewModel.updatePassword(passwordText: newPassword)
                }
                                    
                FieldInput<PasswordValidationError, PasswordInputField>(
                    title: Strings.PasswordSetup.confirmPasswordFieldLabel,
                    text: $viewModel.confirmPassword,
                    hintText: "8 Chars, 1 upper and 1 number",
                    validationErrors: viewModel.confirmPasswordValidationErrors,
                    showValidationErrors: self.$viewModel.showConfirmationPasswordValidationErrors,
                    content: {
                        PasswordInputField(
                            placeholder: Strings.PasswordSetup.confirmPasswordFieldPlaceholder,
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
        })
    }
}



#Preview {
    let navService = NavigationService()
    PasswordSetupView(
        navigation: navService,
        verificationSessionId: Data(),
        authFlow: .registration)
}
