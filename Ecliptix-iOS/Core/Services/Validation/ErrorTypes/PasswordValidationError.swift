//
//  PasswordValidationError.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

enum PasswordValidationError: String, ValidationError {
    case empty = "Cannot be empty"
    case tooShort = "At least 8 characters"
    case missingUppercase = "At least 1 uppercase letter"
    case missingLowercase = "At least 1 lowercase letter"
    case missingDigit = "At least 1 digit"
    case missingSpecialCharacter = "At least 1 special character from the set: \"\""
    case containsDisallowedCharacters = "Contains invalid characters"
    
    case mismatchPasswords = "Passwords do not match"
}

extension PasswordValidationError {
    func formatted(minLength: Int = 8, characterSet: String = "") -> String {
        switch self {
        case .tooShort:
            return "At least \(minLength) characters"
        case .missingSpecialCharacter:
            return "At least 1 special character from the set: \(characterSet)"
        default:
            return self.rawValue
        }
    }
}
