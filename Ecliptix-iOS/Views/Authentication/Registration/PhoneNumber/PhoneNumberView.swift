//
//  PhoneNumberView.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 20.05.2025.
//

import SwiftUI

struct PhoneNumberView: View {
    @StateObject private var viewModel: PhoneNumberViewModel
    
    init(navigation: NavigationService) {
        _viewModel = StateObject(wrappedValue: PhoneNumberViewModel(navigation: navigation))
    }

    var body: some View {
        AuthScreenContainer(spacing: 24, content: {
            AuthViewHeader(
                viewTitle: Strings.PhoneNumber.title,
                viewDescription: Strings.PhoneNumber.description
            )
            
            FieldInput<PhoneValidationError, PhoneInputField>(
                title: "Phone Number",
                text: $viewModel.phoneNumber,
                hintText: "Include country code",
                validationErrors: viewModel.validationErrors,
                content: {
                    PhoneInputField(
                        phoneCode: $viewModel.phoneCode,
                        phoneNumber: $viewModel.phoneNumber
                    )
                }
            )
            
            FormErrorText(error: viewModel.errorMessage)
            
            PrimaryActionButton(
                title: Strings.PhoneNumber.Buttons.sendCode,
                isLoading: viewModel.isLoading,
                isEnabled: !viewModel.phoneNumber.isEmpty && !viewModel.isLoading,
                action: viewModel.submitPhone
            )
            
            Spacer()
        })
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}


#Preview {
    let navService = NavigationService()
    return PhoneNumberView(navigation: navService)
        .environmentObject(navService)
}
