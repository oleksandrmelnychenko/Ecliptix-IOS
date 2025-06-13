//
//  PasswordValidator.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import Foundation

struct PasswordValidator {
    static func hasMinLength(_ password: String, length: Int = 8) -> Bool {
        password.count >= length
    }

    static func hasUppercase(_ password: String) -> Bool {
        let pattern = ".*[A-Z]+.*"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: password)
    }

    static func hasDigit(_ password: String) -> Bool {
        let pattern = ".*[0-9]+.*"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: password)
    }

    static func isValid(_ password: String) -> Bool {
        hasMinLength(password) && hasUppercase(password) && hasDigit(password)
    }

    static func validationErrors(for password: String) -> [PasswordValidationError] {
        var errors: [PasswordValidationError] = []
        if !hasMinLength(password) {
            errors.append(.tooShort)
        }
        if !hasUppercase(password) {
            errors.append(.missingUppercase)
        }
        if !hasDigit(password) {
            errors.append(.missingDigit)
        }
        return errors
    }
}

enum PasswordValidationError: String, CaseIterable, Identifiable {
    case tooShort = "At least 8 characters"
    case missingUppercase = "At least 1 uppercase letter"
    case missingDigit = "At least 1 number"

    var id: String { rawValue }
}

