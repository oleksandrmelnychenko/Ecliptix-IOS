//
//  PasswordValidationError.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

enum PasswordValidationError: String, ValidationError {
    case tooShort = "At least 8 characters"
    case missingUppercase = "At least 1 uppercase letter"
    case missingDigit = "At least 1 number"
    case mismatchPasswords = "Passwords do not match"
}
