//
//  PasswordValidationError.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

import Foundation

enum PasswordValidationError: ValidationError {
    case empty
    case tooShort(Int)
    case missingUppercase
    case missingLowercase
    case missingDigit
    case missingSpecialCharacter(String)
    case containsDisallowedCharacters
    case mismatchPasswords
    
    
    var message: String {
        switch self {
        case .empty:
            return String(localized: "Password cannot be empty")
        case .tooShort(let length):
            return String(localized: "At least \(length) characters")
        case .missingUppercase:
            return String(localized: "At least 1 uppercase letter")
        case .missingLowercase:
            return String(localized: "At least 1 lowercase letter")
        case .missingDigit:
            return String(localized: "At least 1 digit")
        case .missingSpecialCharacter(let set):
            return String(localized: "At least 1 special character from the set: \(set)")
        case .containsDisallowedCharacters:
            return String(localized: "Contains invalid characters")
        case .mismatchPasswords:
            return String(localized: "Passwords do not match")
        }
    }
}
