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
        VStack(alignment: .leading, spacing: 24) {
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

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.horizontal)
            }

            Button(action: {
                viewModel.submitPhone()
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text(Strings.PhoneNumber.Buttons.sendCode)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(viewModel.phoneNumber.isEmpty || viewModel.isLoading ? Color.gray : Color.black)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(viewModel.phoneNumber.isEmpty || viewModel.isLoading)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 100)
    }
}


#Preview {
    let navService = NavigationService()
    return PhoneNumberView(navigation: navService)
        .environmentObject(navService)
}
