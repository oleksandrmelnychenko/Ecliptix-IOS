//
//  PhoneValidationError.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

enum PhoneValidationError: String, ValidationError {
    case invalidFormat = "Invalid phone number format"
    case empty = "Phone number cannot be empty"
}
