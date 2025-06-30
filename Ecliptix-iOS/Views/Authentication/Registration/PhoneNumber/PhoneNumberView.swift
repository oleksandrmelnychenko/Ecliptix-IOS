//
//  PhoneNumberView.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 20.05.2025.
//

import SwiftUI

struct PhoneNumberView: View {
    @StateObject private var viewModel: PhoneNumberViewModel
    @State private var isShowingCountryPicker = false

    init(navigation: NavigationService) {
        _viewModel = StateObject(wrappedValue: PhoneNumberViewModel(navigation: navigation))
    }

    var body: some View {
        AuthScreenContainer(spacing: 24, content: {
            AuthViewHeader(
                viewTitle: Strings.PhoneNumber.title,
                viewDescription: Strings.PhoneNumber.description
            )
            
            if let selectedCountry = viewModel.selectedCountry {
                VStack(spacing: 16) {
                    CountryPickerButton(
                        selectedCountry: Binding(
                            get: { selectedCountry },
                            set: { viewModel.selectedCountry = $0 }
                        ),
                        isShowingCountryPicker: $isShowingCountryPicker,
                        countries: viewModel.countries
                    )
                    
                    FieldInput<PhoneValidationError, PhoneNumberInputField>(
                        title: "Phone Number",
                        text: $viewModel.phoneNumber,
                        hintText: "Include country code",
                        validationErrors: viewModel.validationErrors,
                        content: {
                            PhoneNumberInputField(
                                phoneCode: selectedCountry.phoneCode,
                                phoneNumber: $viewModel.phoneNumber)
                        }
                    )
                }
            } else {
                ProgressView("Loading countries...")
            }
            
            
            FormErrorText(error: viewModel.errorMessage)
            
            PrimaryActionButton(
                title: Strings.PhoneNumber.Buttons.sendCode,
                isLoading: viewModel.isLoading,
                isEnabled: !viewModel.phoneNumber.isEmpty && !viewModel.isLoading,
                action: viewModel.submitPhone
            )
            
            Spacer()
        })
    }
}

struct PhoneNumberInputField: View {
    var phoneCode: String
    @Binding var phoneNumber: String
    
    var body: some View {
        HStack(spacing: 0) {
            Text(phoneCode)
                .foregroundColor(.black)
                .frame(width: 50, alignment: .center)
                .padding(.horizontal, 8)
            
            Divider()
            
            TextField(Strings.PhoneNumber.Buttons.sendCode, text: $phoneNumber)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .autocapitalization(.none)
                .padding(.horizontal, 8)
                .accessibilityLabel(Strings.PhoneNumber.phoneFieldLabel)
                .accessibilityHint(Strings.PhoneNumber.phoneFieldHint)
        }
        .frame(height: 25)
    }
}


#Preview {
    let navService = NavigationService()
    return PhoneNumberView(navigation: navService)
        .environmentObject(navService)
}
