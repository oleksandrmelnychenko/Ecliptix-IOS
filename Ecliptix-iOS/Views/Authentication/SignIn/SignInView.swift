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
    
    @State private var isPhoneFocused: Bool = false
    @State private var isPasswordFocused: Bool = false
        
    init() {
        _viewModel = StateObject(wrappedValue: SignInViewModel())
    }
    
    var body: some View {
        AuthScreenContainer(
            spacing: 24,
            canGoBack: self.navigation.canGoBack()) {
                
            AuthViewHeader(
                viewTitle: Strings.Authentication.SignIn.title,
                viewDescription: Strings.Authentication.SignIn.description
            )
            
            Group {
                FieldInput<PhoneValidationError>(
                    hintText: Strings.Authentication.SignIn.mobileHint,
                    validationErrors: viewModel.phoneValidationErrors,
                    showValidationErrors: self.$viewModel.showPhoneNumberErrors,
                    isFocused: $isPhoneFocused,
                    content: {
                        PhoneInputField(
                            phoneNumber: $viewModel.phoneNumber,
                            placeholder: Strings.Authentication.SignIn.mobilePlaceholder,
                            isFocused: $isPhoneFocused
                        )
                    }
                )
                .onChange(of: viewModel.phoneNumber) { _, _ in
                    if !self.viewModel.showPhoneNumberErrors {
                        self.viewModel.showPhoneNumberErrors = true
                    }
                }

                
                FieldInput<PasswordValidationError>(
                    hintText: Strings.Authentication.SignIn.passwordHint,
                    validationErrors: viewModel.passwordValidationErrors,
                    showValidationErrors: self.$viewModel.showPasswordValidationErrors,
                    isFocused: $isPasswordFocused,
                    content: {
                        SecurePasswordField(
                            placeholder: Strings.Authentication.SignIn.passwordPlaceholder,
                            onCharacterAdded: { index, chars in
                                viewModel.insertSecureKeyChars(indext: index, chars: chars)
                            },
                            onCharacterRemoved: { index, count in
                                viewModel.removeSecureKeyChars(index: index, count: count)
                            },
                            isFocused: $isPasswordFocused
                        )
                    }
                )
            }
            
            FormErrorText(error: viewModel.errorMessage)
                        
            VStack {
                PrimaryButton(
                    title: Strings.Authentication.SignIn.continueButton,
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
                    title: Strings.Authentication.SignIn.accountRecovery,
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
