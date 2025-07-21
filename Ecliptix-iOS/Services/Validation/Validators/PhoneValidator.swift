//
//  PhoneValidator.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

import Foundation

struct PhoneValidator: FieldValidating {
    private static let minDigits: Int = 7
    private static let maxDigits: Int = 15
    
    private static let nonDigitsRegex = try! NSRegularExpression(pattern: "[^0-9]")
    
    func validate(_ value: String) -> [PhoneValidationError] {
        let rules: [(String) -> PhoneValidationError?] = [
            checkEmpty,
            checkMissingCountryCode,
            checkContainsNonDigits,
            checkInvalidLength
        ]

        var errors: [PhoneValidationError] = []

        for rule in rules {
            if let error = rule(value) {
                errors.append(error)
            }
        }

        return errors
    }
    
    // MARK: - Validation Rules
    private func checkEmpty(_ value: String) -> PhoneValidationError? {
        return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .empty : nil
    }

    private func checkMissingCountryCode(_ value: String) -> PhoneValidationError? {
        return !value.hasPrefix("+") ? .missingCountryCode : nil
    }

    private func checkContainsNonDigits(_ value: String) -> PhoneValidationError? {
        let numberPart = String(value.dropFirst())
        let range = NSRange(location: 0, length: numberPart.utf16.count)
        
        return Self.nonDigitsRegex.firstMatch(in: numberPart, range: range) != nil
            ? .containsNonDigits
            : nil
    }

    private func checkInvalidLength(_ value: String) -> PhoneValidationError? {
        let numberPart = value.dropFirst()
        let length = numberPart.count
        
        return (length < Self.minDigits || length > Self.maxDigits)
            ? .invalidLength(min: Self.minDigits, max: Self.maxDigits)
            : nil
    }
}
