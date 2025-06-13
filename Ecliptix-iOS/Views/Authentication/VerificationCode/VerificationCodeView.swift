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
    
    init(phoneNumber: String, navigation: NavigationService) {
        self.phoneNumber = phoneNumber
        _viewModel = StateObject(wrappedValue: VerificationCodeViewModel(
            phoneNumber: phoneNumber,
            navigation: navigation
        ))
    }

    var body: some View {
        VStack(alignment: .leading) {
            AuthViewHeader(
                viewTitle: Strings.VerificationCode.title,
                viewDescription: Strings.VerificationCode.description
            )
            .padding(.bottom, 24)

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
            .padding(.bottom, 24)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.horizontal)
            }

            Button(action: {
                viewModel.verifyCode {
                    focusedField = 0
                }
            }) {
                Text(Strings.VerificationCode.Buttons.verifyCode)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.combinedCode.contains(VerificationCodeViewModel.emptySign) ? Color.gray : Color.black)
                    .cornerRadius(10)
            }
            .disabled(viewModel.combinedCode.contains(VerificationCodeViewModel.emptySign))
            .padding(.bottom, 16)

            HStack {
                Spacer()
                Button(Strings.VerificationCode.Buttons.resendCode) {
                    viewModel.resetCode()
                    focusedField = 0
                }
                .foregroundColor(.gray)
                .underline()
                Spacer()
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 100)
    }
}

#Preview {
    let navService = NavigationService()
    VerificationCodeView(phoneNumber: "+380123123123", navigation: navService)
}
