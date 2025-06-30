//
//  SignInView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.06.2025.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var navigation: NavigationService
    @StateObject private var viewModel: SignInViewModel
    
    init(navigation: NavigationService) {
        _viewModel = StateObject(wrappedValue: SignInViewModel(
            navigation: navigation
        ))
    }
    
    var body: some View {
        AuthScreenContainer(spacing: 24, content: {
            AuthViewHeader(
                viewTitle: Strings.SignIn.title,
                viewDescription: Strings.SignIn.description
            )
            
            Group {
                FieldInput<PhoneValidationError, PhoneNumberInputField>(
                    title: "Phone Number",
                    text: $viewModel.phoneNumber,
                    hintText: "Include country code",
                    validationErrors: viewModel.phoneValidationErrors,
                    content: {
                        PhoneNumberInputField(
                            phoneCode: "+380",
                            phoneNumber: $viewModel.phoneNumber)
                    }
                )
                                    
                FieldInput<PasswordValidationError, PasswordInputField>(
                    title: Strings.PasswordSetup.confirmPasswordFieldLabel,
                    text: $viewModel.password,
                    hintText: "8 Chars, 1 upper and 1 number",
                    validationErrors: viewModel.passwordValidationErrors,
                    content: {
                        PasswordInputField(
                            placeholder: Strings.PasswordSetup.confirmPasswordFieldPlaceholder,
                            text: $viewModel.password,
                        )
                    }
                ).onChange(of: viewModel.password) { _, newPassword in
                    viewModel.updatePassword(passwordText: newPassword)
                }
            }
            
            FormErrorText(error: viewModel.errorMessage)
            
            PrimaryActionButton(
                title: Strings.PasswordSetup.Buttons.next,
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.isFormValid && !viewModel.isLoading,
                action: {
                    Task {
                        await viewModel.signInButton()
                    }
                }
            )
            
            Spacer()
        })
    }
}

#Preview {
    let navService = NavigationService()
    SignInView(navigation: navService)
}
