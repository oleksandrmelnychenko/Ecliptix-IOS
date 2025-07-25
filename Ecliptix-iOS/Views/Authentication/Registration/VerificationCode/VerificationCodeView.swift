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
    
    let phoneNumber: String
    
    init(phoneNumber: String, phoneNumberIdentifier: Data, authFlow: AuthFlow) {
        self.phoneNumber = phoneNumber
        _viewModel = StateObject(wrappedValue: VerificationCodeViewModel(
            phoneNumber: phoneNumber,
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
                viewTitle: String(localized: "Verify your number"),
                viewDescription: String(localized: "We have sent a code to your phone to verify your identity.")
            )
                
            // TODO: Refactore this
            VStack(spacing: 8) {
                Text(String(localized: "Enter the 6-digit code sent to"))
                    .font(.subheadline)

                Text(phoneNumber)
                    .font(.subheadline)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom)

            HStack {
                Spacer()
                ZStack {
                    HStack(spacing: 10) {
                        ForEach(0..<VerificationCodeViewModel.otpLength, id: \.self) { index in
                            OneTimeCodeTextField(
                                text: $viewModel.codeDigits[index],
                                isFirstResponder: focusedField == index,
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
                Text(String(localized: "Resend available in \(viewModel.remainingTime)"))
                    .font(.footnote)
            }
            
            
            FormErrorText(error: viewModel.errorMessage)
            
            if viewModel.secondsRemaining <= 0 {
                PrimaryButton(
                    title: String(localized: "Resend code"),
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
            }
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
            if shouldNavigate,
               let identifier = viewModel.uniqueIdentifier {
                navigation.navigate(to: .passwordSetup(
                    verificationSessionId: identifier,
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
        phoneNumber: "+380123123123",
        phoneNumberIdentifier: Data(),
        authFlow: .registration)
    .environmentObject(navService)
    .environmentObject(localService)
}
