//
//  SignInView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.06.2025.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var navigation: NavigationService
    @EnvironmentObject private var localization: LocalizationService
    
    @StateObject private var viewModel: SignInViewModel
    @State private var showPassword = false
        
    init() {
        _viewModel = StateObject(wrappedValue: SignInViewModel())
    }
    
    var body: some View {
        AuthScreenContainer(
            spacing: 24,
            canGoBack: self.navigation.canGoBack()) {
                
            AuthViewHeader(
                viewTitle: String(localized: "Sign in"),
                viewDescription: String(localized: "Welcome back! Your personalized experience awaits.")
            )
            
            Group {
                FieldInput<PhoneValidationError, PhoneInputField>(
                    title: String(localized: "Phone Number"),
                    text: $viewModel.phoneNumber,
                    hintText: String(localized: "Start with country code."),
                    validationErrors: viewModel.phoneValidationErrors,
                    showValidationErrors: self.$viewModel.showPhoneNumberErrors,
                    content: {
                        PhoneInputField(
                            phoneNumber: $viewModel.phoneNumber)
                    }
                )
                .onChange(of: viewModel.phoneNumber) { _, _ in
                    if !self.viewModel.showPhoneNumberErrors {
                        self.viewModel.showPhoneNumberErrors = true
                    }
                }
                
                FieldInput<PasswordValidationError, PasswordInputField>(
                    title: String(localized: "Password"),
                    text: $viewModel.password,
                    hintText: String(localized: "Stored only on your device"),
                    validationErrors: viewModel.passwordValidationErrors,
                    showValidationErrors: self.$viewModel.showPasswordValidationErrors,
                    content: {
                        PasswordInputField(
                            placeholder: String(localized: "Secret Key"),
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
                
                PrimaryButton(
                    title: String(localized: "Account recovery"),
                    isEnabled: !viewModel.isLoading,
                    isLoading: viewModel.isLoading,
                    style: .light,
                    action: viewModel.forgotPasswordTapped
                )
            }
        }
        .onChange(of: viewModel.shouldNavigateToRecoveryPassword) { _, shouldNavigate in
            if shouldNavigate {
                navigation.navigate(to: .phoneNumberVerification(authFlow: .recovery))
                
                DispatchQueue.main.async {
                    viewModel.shouldNavigateToRecoveryPassword = false
                }
            }
        }
        .onChange(of: viewModel.shouldNavigateToMainApp) { _, shouldNavigate in
            if shouldNavigate {
                navigation.navigate(to: .passPhaseLogin)
                
                DispatchQueue.main.async {
                    viewModel.shouldNavigateToMainApp = false
                }
            }
        }
    }
}

#Preview {
    let navService = NavigationService()
    let localService = LocalizationService.shared
    SignInView()
        .environmentObject(navService)
        .environmentObject(localService)
}
