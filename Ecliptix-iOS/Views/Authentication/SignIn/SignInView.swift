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
    @State private var showPassword = false
    
    init(navigation: NavigationService) {
        _viewModel = StateObject(wrappedValue: SignInViewModel(
            navigation: navigation
        ))
    }
    
    var body: some View {
        AuthScreenContainer(
            spacing: 24, canGoBack:
                self.viewModel.navigation.canGoBack()) {
                AuthViewHeader(
                    viewTitle: String(localized: "Sign in"),
                    viewDescription: String(localized: "Welcome back! Your personalized experience awaits.")
                )
                
                Group {
                    FieldInput<PhoneValidationError, PhoneInputField>(
                        title: String(localized: "Phone Number"),
                        text: $viewModel.phoneNumber,
                        hintText: String(localized: "Include country code"),
                        validationErrors: viewModel.phoneValidationErrors,
                        showValidationErrors: self.$viewModel.showPhoneNumberErrors,
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
                        showValidationErrors: self.$viewModel.showPasswordValidationErrors,
                        content: {
                            PasswordInputField(
                                placeholder: String(localized: "Enter password"),
                                showPassword: $showPassword,
                                text: $viewModel.password
                            )
                        }
                    )
                    .onChange(of: viewModel.password) { _, newPassword in
                        self.viewModel.updatePassword(passwordText: newPassword)
                    }
                }
                
                FormErrorText(error: viewModel.errorMessage)
                
                Spacer()
                
                VStack {
                    PrimaryButton(
                        title: String(localized: "Account recovery"),
                        isEnabled: viewModel.isFormValid && !viewModel.isLoading,
                        isLoading: viewModel.isLoading,
                        style: .light,
                        action: viewModel.forgotPasswordTapped
                    )
                    
                    PrimaryButton(
                        title: String(localized: "Next"),
                        isEnabled: viewModel.isFormValid && !viewModel.isLoading,
                        isLoading: viewModel.isLoading,
                        style: .dark,
                        action: {
                            Task {
                                await viewModel.signInButton()
                            }
                        }
                    )
                }
            }
    }
}

#Preview {
    let navService = NavigationService()
    SignInView(navigation: navService)
}
