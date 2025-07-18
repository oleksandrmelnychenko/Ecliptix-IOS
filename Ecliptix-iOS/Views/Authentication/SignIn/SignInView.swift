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
        ScrollView {
            VStack {
                HStack {
                    Spacer()
                    Image("EcliptixLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                    Spacer()
                }
                .padding(.top, 15)
                
                VStack(spacing: 24) {
                    AuthViewHeader(
                        viewTitle: String(localized: "Sign in"),
                        viewDescription: String(localized: "Welcome back! Your personalized experience awaits.")
                    )
                    
                    TextField(
                        "Mobile number",
                        text: $viewModel.password
                    )
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .font(.title3)
                    .padding(.horizontal, 8)
                    .onChange(of: viewModel.password) { _, newValue in
                        viewModel.password = sanitizePhoneNumber(newValue)
                    }
                    .frame(height: 30)
                    .padding(.horizontal, 8)
                    .padding(.top, 15)
                    .padding(.bottom, 10)
                    
                    
                    PhoneInputField(
                        phoneNumber: $viewModel.phoneNumber)
                    .padding(.horizontal, 8)
                    .padding(.top, 15)
                    .padding(.bottom, 10)
                    
                    FormErrorText(error: viewModel.errorMessage)
                    
                    HStack {
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
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(.keyboard)
    }
    
    
    private func sanitizePhoneNumber(_ input: String) -> String {
        let digits = input.filter { $0.isWholeNumber }

        if digits.isEmpty {
            return ""
        } else {
            return "+" + digits
        }
    }
}

#Preview {
    let navService = NavigationService()
    SignInView(navigation: navService)
}


//VStack(alignment: .leading, spacing: 6) {
//                            VStack(spacing: 0) {
//                                PhoneInputField(
//                                    phoneNumber: $viewModel.password)
//                                .padding(.horizontal, 8)
//                                .padding(.top, 15)
//                                .padding(.bottom, 10)
//
//                                HStack(alignment: .bottom) {
//                                    Image(systemName: "lightbulb.min")
//                                    Text(String(localized: "8 Chars, 1 upper and 1 number"))
//
//                                    Spacer()
//                                }
//                                .foregroundColor(Color("Tip.Highlight"))
//                                .font(.subheadline)
//                                .padding(.horizontal, 8)
//                                .padding(.bottom, 5)
//                            }
//                            .background(Color("Textbox.Background"))
//                            .cornerRadius(10)
//
//                            VStack(alignment: .leading, spacing: 4) {
//                                if self.viewModel.showPhoneNumberErrors, let firstError = self.viewModel.passwordValidationErrors.first {
//                                    ValidationMessageView(text: firstError.rawValue)
//                                }
//                            }
//                            .animation(.easeInOut, value: viewModel.phoneNumber)
//                        }
                        
                        //                FieldInput<PasswordValidationError, PasswordInputField>(
                        //                    title: String(localized: "Password"),
                        //                    text: $viewModel.password,
                        //                    hintText: String(localized: "8 Chars, 1 upper and 1 number"),
                        //                    validationErrors: viewModel.passwordValidationErrors,
                        //                    showValidationErrors: self.$viewModel.showPasswordValidationErrors,
                        //                    content: {
                        //                        PasswordInputField(
                        //                            placeholder: String(localized: "Enter password"),
                        //                            showPassword: $showPassword,
                        //                            text: $viewModel.password
                        //                        )
                        //                    }
                        //                )
                        //                .onChange(of: viewModel.password) { _, newPassword in
                        //                    self.viewModel.updatePassword(passwordText: newPassword)
                        //                }
                        
                        
                        //                FieldInput<PhoneValidationError, PhoneInputField>(
                        //                    title: String(localized: "Phone Number"),
                        //                    text: $viewModel.phoneNumber,
                        //                    hintText: String(localized: "Include country code"),
                        //                    validationErrors: viewModel.phoneValidationErrors,
                        //                    showValidationErrors: self.$viewModel.showPhoneNumberErrors,
                        //                    content: {
                        //                        PhoneInputField(
                        //                            phoneNumber: $viewModel.phoneNumber)
                        //                    }
                        //                )
                        

                        
//                        VStack(alignment: .leading, spacing: 6) {
//                            VStack(spacing: 0) {
//                                PhoneInputField(
//                                    phoneNumber: $viewModel.phoneNumber)
//                                .padding(.horizontal, 8)
//                                .padding(.top, 15)
//                                .padding(.bottom, 10)
//
//                                HStack(alignment: .bottom) {
//                                    Image(systemName: "lightbulb.min")
//                                    Text(String(localized: "Include country code"))
//
//                                    Spacer()
//                                }
//                                .foregroundColor(Color("Tip.Highlight"))
//                                .font(.subheadline)
//                                .padding(.horizontal, 8)
//                                .padding(.bottom, 5)
//                            }
//                            .background(Color("Textbox.Background"))
//                            .cornerRadius(10)
//
//                            VStack(alignment: .leading, spacing: 4) {
//                                if self.viewModel.showPhoneNumberErrors, let firstError = self.viewModel.phoneValidationErrors.first {
//                                    ValidationMessageView(text: firstError.rawValue)
//                                }
//                            }
//                            .animation(.easeInOut, value: viewModel.phoneNumber)
//                        }
