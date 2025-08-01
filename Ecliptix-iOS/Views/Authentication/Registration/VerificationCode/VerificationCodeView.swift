//
//  VerificationCodeView.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 20.05.2025.
//

import SwiftUI

struct VerificationCodeView: View {
    @EnvironmentObject private var navigation: NavigationService
    @EnvironmentObject private var localization: LocalizationService
    
    @StateObject private var viewModel: VerificationCodeViewModel
    
    @FocusState private var focusedField: Int?
        
    init(phoneNumberIdentifier: Data, authFlow: AuthFlow) {
        _viewModel = StateObject(wrappedValue: VerificationCodeViewModel(
            phoneNumberIdentifier: phoneNumberIdentifier,
            authFlow: authFlow
        ))
    }

    var body: some View {
        AuthScreenContainer(
            spacing: 24,
            canGoBack: self.navigation.canGoBack(),
            content: {
            AuthViewHeader(
                viewTitle: Strings.Authentication.SignUp.VerificationCodeEntry.title,
                viewDescription: Strings.Authentication.SignUp.VerificationCodeEntry.description
            )


            HStack {
                Spacer()
                ZStack {
                    HStack(spacing: 10) {
                        ForEach(0..<VerificationCodeViewModel.otpLength, id: \.self) { index in
                            OneTimeCodeTextField(
                                text: $viewModel.codeDigits[index],
                                isFocused: Binding(
                                    get: { focusedField == index },
                                    set: { newValue in
                                        if newValue {
                                            focusedField = index
                                        }
                                    }
                                ),
                                showError: $viewModel.showCodeError,
                                onBackspace: {
                                    viewModel.handleBackspace(at: index, focus: &focusedField)
                                },
                                onInput: { newValue in
                                    viewModel.handleInput(newValue, at: index, focus: &focusedField)
                                }
                            )
                            .focused($focusedField, equals: index)
                            .frame(width: 44, height: 55)
                        }
                    }
                    .onAppear {
                        focusedField = 0
                    }
                    
                    Color.white.opacity(0.01)
                        .frame(height: 55)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            
                            if let firstEmpty = viewModel.codeDigits.firstIndex(where: { $0 == VerificationCodeViewModel.emptySign }) {
                                focusedField = firstEmpty
                            } else {
                                focusedField = VerificationCodeViewModel.otpLength - 1
                            }
                        }
                }
                Spacer()
            }
                
            
            if viewModel.secondsRemaining > 0 {
                Text(viewModel.remainingTime)
                    .font(.footnote)
            }
            
            
            FormErrorText(error: viewModel.errorMessage)
            
            PrimaryButton(
                title: Strings.Authentication.SignUp.VerificationCodeEntry.Button.resend,
                isEnabled: viewModel.secondsRemaining <= 0,
                isLoading: viewModel.isLoading,
                style: .light,
                action: {
                    Task {
                        focusedField = 0
                        await viewModel.reSendVerificationCode()
                    }
                }
            )
        })
        .onAppear {
            viewModel.startValidation()
        }
        .onChange(of: viewModel.combinedCode) {_, newValue in
            let isComplete = !newValue.contains(VerificationCodeViewModel.emptySign)
            if isComplete && !viewModel.isLoading {
                Task {
                    await viewModel.verifyCode {
                        focusedField = 0
                    }
                }
            }
        }
        .onChange(of: viewModel.shouldNavigateToPasswordSetUp) { _, shouldNavigate in
            if shouldNavigate {
                navigation.navigate(to: .passwordSetup(
                    authFlow: viewModel.authFlow
                ))
                
                DispatchQueue.main.async {
                    viewModel.shouldNavigateToPasswordSetUp = false
                }
            }
        }
    }
}

#Preview {
    let navService = NavigationService()
    let localService = LocalizationService.shared
    VerificationCodeView(
        phoneNumberIdentifier: Data(),
        authFlow: .registration)
            .environmentObject(navService)
            .environmentObject(localService)
}
