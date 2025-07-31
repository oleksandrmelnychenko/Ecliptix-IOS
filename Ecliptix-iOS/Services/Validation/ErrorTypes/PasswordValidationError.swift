//
//  PasswordValidationError.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

import Foundation

enum PasswordValidationError: ValidationError {
    case required
    case minLength(Int)
    case maxLength(Int)
    case noUppercase
    case noSpaces
    case tooSimple
    case tooCommon
    case noDigit
    case sequentialPattern
    case repeatedChars
    case lacksDiversity(requiredTypes: Int)
    case containsAppName
    case nonEnglishLetters
    
    case mismatchPasswords
    
    var messageKey: String {
        switch self {
        case .required:
            return Strings.ValidationErrors.SecureKey.required
        case .minLength:
            return Strings.ValidationErrors.SecureKey.minLength
        case .maxLength:
            return Strings.ValidationErrors.SecureKey.maxLength
        case .noUppercase:
            return Strings.ValidationErrors.SecureKey.noUppercase
        case .noSpaces:
            return Strings.ValidationErrors.SecureKey.noSpaces
        case .tooSimple:
            return Strings.ValidationErrors.SecureKey.tooSimple
        case .tooCommon:
            return Strings.ValidationErrors.SecureKey.tooCommon
        case .noDigit:
            return Strings.ValidationErrors.SecureKey.noDigit
        case .sequentialPattern:
            return Strings.ValidationErrors.SecureKey.sequentialPattern
        case .repeatedChars:
            return Strings.ValidationErrors.SecureKey.repeatedChars
        case .lacksDiversity:
            return Strings.ValidationErrors.SecureKey.lacksDiversity
        case .containsAppName:
            return Strings.ValidationErrors.SecureKey.containsAppName
        case .nonEnglishLetters:
            return Strings.ValidationErrors.SecureKey.nonEnglishLetters
            
        case .mismatchPasswords:
            return String(localized: "Passwords do not match")
        }
    }
    
    var args: [CVarArg] {
        switch self {
        case .minLength(let length): return [length]
        case .maxLength(let length): return [length]
        case .lacksDiversity(let requiredTypes): return [requiredTypes]
        default: return []
        }
    }
}
