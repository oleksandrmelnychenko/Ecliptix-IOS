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
    case tooLong(Int)
    case leadingOrTrailingSpaces
    case tooSimple
    case tooCommon
    case sequentialPattern
    case excessiveRepeats
    case insufficientCharacterDiversity(requiredTypes: Int)
    case containsAppNameVariant
    
    case mismatchPasswords
    
    
    var message: String {
        switch self {
        case .empty:
            return String(localized: "Required")
        case .tooShort(let length):
            return String(localized: "At least \(length) chars")
        case .tooLong(let length):
            return String(localized: "Max \(length) chars")
        case .leadingOrTrailingSpaces:
            return String(localized: "No leading/trailing spaces")
        case .tooSimple:
            return String(localized: "Too simple; add length or character variety")
        case .tooCommon:
            return String(localized: "Too common")
        case .sequentialPattern:
            return String(localized: "No sequential patterns")
        case .excessiveRepeats:
            return String(localized: "No repeating characters")
        case .insufficientCharacterDiversity(let requiredTypes):
            return String(localized: "Needs \(requiredTypes) chars (a, A, 1, #)")
        case .containsAppNameVariant:
            return String(localized: "Cannot contain app name")

        case .mismatchPasswords:
            return String(localized: "Passwords do not match")
        }
    }
}
