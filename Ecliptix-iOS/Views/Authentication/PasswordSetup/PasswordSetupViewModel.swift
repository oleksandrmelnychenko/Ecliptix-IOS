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
    @Published var showMismatchAlert = false
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

    var isFormValid: Bool {
        isPasswordValid && password == confirmPassword && !password.isEmpty
    }

    func proceed() {
        if password == confirmPassword {
            navigation.navigate(to: .passPhaseRegistration)
        } else {
            showMismatchAlert = true
        }
    }
}
