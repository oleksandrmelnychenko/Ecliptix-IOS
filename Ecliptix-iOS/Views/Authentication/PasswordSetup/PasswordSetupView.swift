//
//  PasswordSetupView.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 20.05.2025.
//

import SwiftUI

struct PasswordSetupView: View {
    @StateObject private var viewModel: PasswordSetupViewModel
    
    init(navigation: NavigationService) {
        _viewModel = StateObject(wrappedValue: PasswordSetupViewModel(navigation: navigation))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            AuthViewHeader(
                viewTitle: Strings.PasswordSetup.title,
                viewDescription: Strings.PasswordSetup.description
            )
            
            Group {
                // Password field
                PasswordFieldView(
                    title: Strings.PasswordSetup.passwordFieldLabel,
                    text: $viewModel.password,
                    placeholder: Strings.PasswordSetup.passwordFieldPlaceholder,
                    validationErrors: viewModel.validationErrors
                )
                .padding(.bottom, 16)
                                    
                // Confirm password field
                PasswordFieldView(
                    title: Strings.PasswordSetup.confirmPasswordFieldLabel,
                    text: $viewModel.confirmPassword,
                    placeholder: Strings.PasswordSetup.confirmPasswordFieldPlaceholder
                )
            }
            
            Button(action: {
                viewModel.proceed()
            }) {
                Text(Strings.PasswordSetup.Buttons.next)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .alert("Passwords do not match", isPresented: $viewModel.showMismatchAlert) {
                Button("OK", role: .cancel) {}
            }
            .padding(.top, 24)
            
            Spacer()
            
        }
        .padding(.horizontal, 24)
        .padding(.top, 100)
    }
}

#Preview {
    let navService = NavigationService()
    return PasswordSetupView(navigation: navService)
        .environmentObject(navService)
}
