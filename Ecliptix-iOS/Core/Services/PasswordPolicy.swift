//
//  PasswordPolicy.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

struct PasswordPolicy {
    let minLength: Int
    let requireLowercase: Bool
    let requireUppercase: Bool
    let requireDigit: Bool
    let requireSpecialChar: Bool
    let allowedSpecialChars: String
    let enforceAllowedCharsOnly: Bool

    static let standard = PasswordPolicy()

    init(
        minLength: Int = 8,
        requireLowercase: Bool = true,
        requireUppercase: Bool = true,
        requireDigit: Bool = true,
        requireSpecialChar: Bool = true,
        allowedSpecialChars: String = "@$!%*?&",
        enforceAllowedCharsOnly: Bool = false
    ) {
        self.minLength = minLength
        self.requireLowercase = requireLowercase
        self.requireUppercase = requireUppercase
        self.requireDigit = requireDigit
        self.requireSpecialChar = requireSpecialChar
        self.allowedSpecialChars = allowedSpecialChars
        self.enforceAllowedCharsOnly = enforceAllowedCharsOnly
    }
}

