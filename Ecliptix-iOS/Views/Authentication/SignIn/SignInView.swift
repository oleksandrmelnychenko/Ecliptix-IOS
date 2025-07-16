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
                viewTitle: String(localized: "Sign in into account"),
                viewDescription: String(localized: "Enter your email and password to sign in")
            )
            
            Group {
                FieldInput<PhoneValidationError, PhoneInputField>(
                    title: String(localized: "Phone Number"),
                    text: $viewModel.phoneNumber,
                    hintText: String(localized: "Include country code"),
                    validationErrors: viewModel.phoneValidationErrors,
                    content: {
                        PhoneInputField(
                            phoneNumber: $viewModel.phoneNumber)
                    }
                )
                                    
                FieldInput<PasswordValidationError, PasswordInputField>(
                    title: String(localized: "Password"),
                    text: $viewModel.password,
                    hintText: String(localized: "8 Chars, 1 upper and 1 number"),
                    validationErrors: viewModel.passwordValidationErrors,
                    content: {
                        PasswordInputField(
                            placeholder: String(localized: "Enter password"),
                            text: $viewModel.password,
                        )
                    }
                ).onChange(of: viewModel.password) { _, newPassword in
                    self.viewModel.updatePassword(passwordText: newPassword)
                }
                
                Button(action: {
                    viewModel.forgotPasswordTapped()
                }) {
                    Text("Forgot password?")
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.top, -8)
                .padding(.bottom, 8)
            }
            
            FormErrorText(error: viewModel.errorMessage)
            
            PrimaryActionButton(
                title: String(localized: "Next"),
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
