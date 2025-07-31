//
//  PhoneValidationError.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

enum PhoneValidationError: ValidationError {
    case cannotBeEmpty
    case mustStartWithCountryCode
    case containsNonDigits
    case incorrectLength(min: Int, max: Int)
    
    var messageKey: String {
        switch self {
        case .cannotBeEmpty:
            return Strings.ValidationErrors.PhoneNumber.cannotBeEmpty
        case .mustStartWithCountryCode:
            return Strings.ValidationErrors.PhoneNumber.mustStartWithCountryCode
        case .containsNonDigits:
            return Strings.ValidationErrors.PhoneNumber.containsNonDigits
        case .incorrectLength:
            return Strings.ValidationErrors.PhoneNumber.incorrectLength
        }
    }
    
    var args: [CVarArg] {
        switch self {
        case .incorrectLength(let min, let max):
            return [min, max]
        default:
            return []
        }
    }
}
