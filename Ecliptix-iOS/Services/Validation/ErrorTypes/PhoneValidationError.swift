//
//  PhoneValidationError.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

enum PhoneValidationError: ValidationError {
    case invalidFormat
    case empty
    
    var message: String {
        switch self {
        case .empty:
            return String(localized: "Cannot be empty")
        case .invalidFormat:
            return String(localized: "Invalid phone number format")
        }
    }
}
