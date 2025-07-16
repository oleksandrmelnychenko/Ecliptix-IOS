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

            VStack(spacing: 8) {
                Text(Strings.VerificationCode.explanationText)
                    .font(.subheadline)
                    .foregroundColor(.gray)

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
                Text("Resend available in \(viewModel.remainingTime)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            
            FormErrorText(error: viewModel.errorMessage)

            PrimaryActionButton(
                title: Strings.VerificationCode.Buttons.verifyCode,
                isLoading: viewModel.isLoading,
                isEnabled: !viewModel.combinedCode.contains(VerificationCodeViewModel.emptySign),
                action: {
                    Task {
                        await viewModel.verifyCode {
                            focusedField = 0
                        }
                    }
                }
            )

            Spacer()
            
            HStack {
                Spacer()
                if viewModel.secondsRemaining <= 0 {
                    Button(Strings.VerificationCode.Buttons.resendCode) {
                        Task {
                            focusedField = 0
                            await viewModel.reSendVerificationCode()
                        }
                    }
                    .disabled(viewModel.isLoading)
                    .underline()
                    Spacer()
                }
            }
        })
        .alert("Session Error", isPresented: $viewModel.showAlert) {
            Button("OK") {
                print("Session restart requested")
            }
        } message: {
            Text(viewModel.alertMessage)
        }
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
