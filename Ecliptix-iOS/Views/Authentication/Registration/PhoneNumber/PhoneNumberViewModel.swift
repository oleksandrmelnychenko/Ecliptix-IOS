//
//  PhoneNumberViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import Foundation

@MainActor
final class PhoneNumberViewModel: ObservableObject {
    @Published var phoneNumber: String = "970177999"
    @Published var phoneCode: String = "+380"
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let navigation: NavigationService
    private let phoneValidator = PhoneValidator()
    
    var fullPhoneNumber: String {
        return phoneCode + phoneNumber
    }
    
    var validationErrors: [PhoneValidationError] {
        phoneValidator.validate(fullPhoneNumber)
    }
    
    init(navigation: NavigationService) {
        self.navigation = navigation
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
}
