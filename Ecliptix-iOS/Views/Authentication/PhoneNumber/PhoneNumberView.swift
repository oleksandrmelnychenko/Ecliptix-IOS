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
                    
                    PhoneInputField(
                        phoneCode: selectedCountry.phoneCode,
                        phoneNumber: $viewModel.phoneNumber,
                        isLoading: viewModel.isLoading,
                        onSubmit: viewModel.submitPhone
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


#Preview {
    let navService = NavigationService()
    return PhoneNumberView(navigation: navService)
        .environmentObject(navService)
}
