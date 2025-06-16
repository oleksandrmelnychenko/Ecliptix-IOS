//
//  PasswordSetupViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import Foundation
import SwiftUI

@MainActor
final class PasswordSetupViewModel: ObservableObject {
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let navigation: NavigationService
    
    init(navigation: NavigationService) {
        self.navigation = navigation
    }

    var isPasswordValid: Bool {
        PasswordValidator.isValid(password)
    }

    var validationErrors: [PasswordValidationError] {
        PasswordValidator.validationErrors(for: password)
    }
    
    var confirmPasswordValidationError: [PasswordValidationError] {
        PasswordValidator.validateMismatch(password, confirmPassword)
    }

    var isFormValid: Bool {
        isPasswordValid && confirmPasswordValidationError.isEmpty
    }

    func submitPassword() {
        guard !password.isEmpty else { return }
        guard !confirmPassword.isEmpty else { return }
        
        errorMessage = nil
        isLoading = true
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                self.isLoading = false
                
                if password == "Admin123" {
                    navigation.navigate(to: .passPhaseRegistration)
                } else {
                    self.errorMessage = Strings.PasswordSetup.Errors.invalidPassword
                }
            }
        }
    }
}
