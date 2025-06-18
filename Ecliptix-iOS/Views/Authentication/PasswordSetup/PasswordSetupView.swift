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
                FieldInput<PasswordValidationError, PasswordInputField>(
                    title: Strings.PasswordSetup.passwordFieldLabel,
                    text: $viewModel.password,
                    hintText: "8 Chars, 1 upper and 1 number",
                    validationErrors: viewModel.passwordValidationErrors,
                    content: {
                        PasswordInputField(
                            placeholder: Strings.PasswordSetup.passwordFieldPlaceholder,
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
                    content: {
                        PasswordInputField(
                            placeholder: Strings.PasswordSetup.confirmPasswordFieldPlaceholder,
                            text: $viewModel.confirmPassword,
                        )
                    }
                ).onChange(of: viewModel.confirmPassword) { _, newConfirmPassword in
                    viewModel.updateConfirmPassword(passwordText: newConfirmPassword)
                }
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

struct PasswordInputField: View {
    @State private var showPassword: Bool = false
    var placeholder: String = ""
    @Binding var text: String
    
    var body: some View {
        HStack {
            if showPassword {
                TextField(placeholder, text: $text)
                    .textContentType(.newPassword)
                    .font(.system(size: 20))
            } else {
                SecureField(placeholder, text: $text)
                    .textContentType(.newPassword)
                    .font(.system(size: 20))
            }
            
            Button(action: {
                showPassword.toggle()
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    let navService = NavigationService()
    return PasswordSetupView(navigation: navService)
        .environmentObject(navService)
}
