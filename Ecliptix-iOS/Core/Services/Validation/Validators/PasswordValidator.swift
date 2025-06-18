//
//  PasswordValidator.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

import Foundation

struct PasswordValidator: FieldValidating {
    private static let lowercaseRegex = try! NSRegularExpression(pattern: "[a-z]", options: [])
    private static let uppercaseRegex = try! NSRegularExpression(pattern: "[A-Z]", options: [])
    private static let digitRegex = try! NSRegularExpression(pattern: "\\d", options: [])
    private static let alphanumericOnlyRegex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9]*$", options: [])
    
    func validate(_ value: String) -> [PasswordValidationError] {
        let valueValidationResult = checkPasswordCompliance(value, policy: PasswordPolicy.standard)
        guard valueValidationResult.isOk else {
            return []
        }
        
        return try! valueValidationResult.unwrap()
    }
    
    func checkPasswordCompliance(_ password: String, policy: PasswordPolicy) -> Result<[PasswordValidationError], EcliptixProtocolFailure> {
        var validationErrors: [PasswordValidationError] = []

        if password.isEmpty {
            validationErrors.append(.empty)
        } else {
            if password.count < policy.minLength {
                validationErrors.append(.tooShort)
            }
            
            let range = NSRange(location: 0, length: password.utf16.count)
            if policy.requireLowercase && Self.lowercaseRegex.firstMatch(in: password, range: range) == nil {
                validationErrors.append(.missingLowercase)
            }
            
            if policy.requireUppercase && Self.uppercaseRegex.firstMatch(in: password, range: range) == nil {
                validationErrors.append(.missingUppercase)
            }
            
            if policy.requireDigit && Self.digitRegex.firstMatch(in: password, range: range) == nil {
                validationErrors.append(.missingDigit)
            }

            if policy.requireSpecialChar && !policy.allowedSpecialChars.isEmpty {
                let escaped = NSRegularExpression.escapedPattern(for: policy.allowedSpecialChars)
                let pattern = "[\(escaped)]"
                
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    if regex.firstMatch(in: password, range: range) == nil {
                        validationErrors.append(.missingSpecialCharacter)
                    }
                }
            }

            if policy.enforceAllowedCharsOnly {
                if !policy.allowedSpecialChars.isEmpty {
                    let escaped = NSRegularExpression.escapedPattern(for: policy.allowedSpecialChars)
                    let pattern = "^[a-zA-Z0-9\(escaped)]*$"
                    
                    if let regex = try? NSRegularExpression(pattern: pattern) {
                        if regex.firstMatch(in: password, range: range) == nil {
                            validationErrors.append(.containsDisallowedCharacters)
                        }
                    }
                } else {
                    if Self.alphanumericOnlyRegex.firstMatch(in: password, range: range) == nil {
                        validationErrors.append(.containsDisallowedCharacters)
                    }
                }
            }
        }
        
        return .success(validationErrors)
    }
}
