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

    var countries: [Country] {
        countryService.countries
    }

    private let countryService = CountryService()

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
                if self.phoneNumber.count >= 7 {
                    self.navigation.navigate(to: .verificationCode(self.phoneNumber))
                } else {
                    self.errorMessage = Strings.PhoneNumber.Errors.invalidFormat
                }
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
