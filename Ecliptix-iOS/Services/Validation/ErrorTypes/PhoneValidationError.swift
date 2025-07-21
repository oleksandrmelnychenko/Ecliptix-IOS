//
//  PhoneValidationError.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

enum PhoneValidationError: ValidationError {
    case empty
    case missingCountryCode
    case containsNonDigits
    case invalidLength(min: Int, max: Int)

    var message: String {
        switch self {
        case .empty:
            return String(localized: "Phone number cannot be empty.")
        case .missingCountryCode:
            return String(localized: "Must start with a country code (+).")
        case .containsNonDigits:
            return String(localized: "Can only contain digits after the country code.")
        case .invalidLength(let min, let max):
            return String(localized: "Must be between \(min) and \(max) digits long.")
        }
    }
}
