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
    
    @State private var isPasswordFocused: Bool = false
    @State private var isConfirmPasswordFocused: Bool = false
    
    init(authFlow: AuthFlow) {
        _viewModel = StateObject(wrappedValue: PasswordSetupViewModel(authFlow: authFlow))
    }

    var body: some View {
        AuthScreenContainer(spacing: 24) {
            AuthViewHeader(
                viewTitle: Strings.Authentication.SignUp.PasswordConfirmation.title,
                viewDescription: Strings.Authentication.SignUp.PasswordConfirmation.description
            )
            
            Group {
                FieldInput<PasswordValidationError>(
                    hintText: Strings.Authentication.SignUp.PasswordConfirmation.passwordHint,
                    validationErrors: viewModel.passwordValidationErrors,
                    showValidationErrors: self.$viewModel.showPasswordValidationErrors,
                    isFocused: $isPasswordFocused,
                    content: {
                        SecurePasswordField(
                            placeholder: String(localized: "Enter Secret Key"),
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
                
                FieldInput<PasswordValidationError>(
                    hintText: Strings.Authentication.SignUp.PasswordConfirmation.verifyPasswordHint,
                    validationErrors: viewModel.confirmPasswordValidationErrors,
                    showValidationErrors: self.$viewModel.showConfirmationPasswordValidationErrors,
                    isFocused: $isConfirmPasswordFocused,
                    content: {
                        SecurePasswordField(
                            placeholder: String(localized: "Confirm Secret Key"),
                            onCharacterAdded: { index, chars in
                                viewModel.insertConfirmSecureKeyChars(indext: index, chars: chars)
                            },
                            onCharacterRemoved: { index, count in
                                viewModel.removeConfirmSecureKeyChars(index: index, count: count)
                            },
                            isFocused: $isConfirmPasswordFocused
                        )
                    }
                )
            }
            
            FormErrorText(error: viewModel.errorMessage)
            
            PrimaryButton(
                title: Strings.Authentication.SignUp.PasswordConfirmation.confirmButton,
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
    
    PasswordSetupView(authFlow: .registration)
        .environmentObject(navService)
        .environmentObject(localService)
}
