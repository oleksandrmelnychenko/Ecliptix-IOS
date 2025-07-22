//
//  VerificationCodeView.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 20.05.2025.
//

import SwiftUI

struct VerificationCodeView: View {
    let phoneNumber: String
    @EnvironmentObject private var navigation: NavigationService
    @StateObject private var viewModel: VerificationCodeViewModel
    @FocusState private var focusedField: Int?
    
    init(navigation: NavigationService, phoneNumber: String, phoneNumberIdentifier: Data, authFlow: AuthFlow) {
        self.phoneNumber = phoneNumber
        _viewModel = StateObject(wrappedValue: VerificationCodeViewModel(
            phoneNumber: phoneNumber,
            phoneNumberIdentifier: phoneNumberIdentifier,
            navigation: navigation,
            authFlow: authFlow
        ))
    }

    var body: some View {
        AuthScreenContainer(spacing: 24, content: {
            AuthViewHeader(
                viewTitle: Strings.VerificationCode.title,
                viewDescription: Strings.VerificationCode.description
            )

            // TODO: Refactore this
            VStack(spacing: 8) {
                Text(Strings.VerificationCode.explanationText)
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
                        ForEach(0..<6, id: \.self) { index in
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
                        .allowsHitTesting(true)
                }
                Spacer()
            }
            
            if viewModel.secondsRemaining > 0 {
                Text(String(localized: "Resend available in \(viewModel.remainingTime)"))
                    .font(.footnote)
            }
            
            
            FormErrorText(error: viewModel.errorMessage)

            PrimaryButton(
                title: String(localized: "Verify"),
                isEnabled: !viewModel.combinedCode.contains(VerificationCodeViewModel.emptySign),
                isLoading: viewModel.isLoading,
                style: .dark,
                action: {
                    Task {
                        await viewModel.verifyCode {
                            focusedField = 0
                        }
                    }
                }
            )
            
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
    }
}

#Preview {
    let navService = NavigationService()
    VerificationCodeView(
        navigation: navService,
        phoneNumber: "+380123123123",
        phoneNumberIdentifier: Data(),
        authFlow: .registration)
}
