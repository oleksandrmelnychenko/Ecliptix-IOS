//
//  PhoneValidator.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

import Foundation

struct PhoneValidator: FieldValidating {
    private static let internationalPhoneRegex = try! NSRegularExpression(
        pattern: #"^\+(?:[0-9] ?){6,14}[0-9]$"#
    )
    
    func validate(_ value: String) -> [PhoneValidationError] {
        var errors: [PhoneValidationError] = []

        if value.isEmpty {
            errors.append(.empty)
        }

        let range = NSRange(location: 0, length: value.utf16.count)
        if Self.internationalPhoneRegex.firstMatch(in: value, options: [], range: range) == nil {
            errors.append(.invalidFormat)
        }

        return errors
    }
}
