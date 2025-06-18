//
//  PasswordValidator.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

struct PasswordValidator: FieldValidating {
    func validate(_ value: String) -> [PasswordValidationError] {
        var errors: [PasswordValidationError] = []
        if value.count < 8 { errors.append(.tooShort) }
        if !value.contains(where: \.isUppercase) { errors.append(.missingUppercase) }
        if !value.contains(where: \.isNumber) { errors.append(.missingDigit) }
        return errors
    }
    
    func validateMatch(_ first: String, _ second: String) -> [PasswordValidationError] {
        first == second ? [] : [.mismatchPasswords]
    }
}
