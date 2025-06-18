//
//  PhoneNumberViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import Foundation

@MainActor
final class PhoneNumberViewModel: ObservableObject {
    @Published var selectedCountry: Country?
    @Published var phoneNumber: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let navigation: NavigationService
    private let countryService = CountryService()
    private let phoneValidator = PhoneValidator()
    
    var countries: [Country] {
        countryService.countries
    }
    
    var fullPhoneNumber: String {
        guard let code = selectedCountry?.phoneCode else { return phoneNumber }
        return code + phoneNumber
    }
    
    var validationErrors: [PhoneValidationError] {
        phoneValidator.validate(fullPhoneNumber)
    }
    
    init(navigation: NavigationService) {
        self.navigation = navigation

        if let first = countryService.countries.first {
            self.selectedCountry = first
        } else {
            Task {
                await waitForCountries()
            }
        }
    }

    func submitPhone() {
        guard !phoneNumber.isEmpty else { return }

        errorMessage = nil
        isLoading = true

        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                self.isLoading = false
                self.navigation.navigate(to: .verificationCode(self.fullPhoneNumber))
            }
        }
    }
    
    private func waitForCountries() async {
        while countryService.countries.isEmpty {
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        selectedCountry = countryService.countries.first
    }
    
    
}
