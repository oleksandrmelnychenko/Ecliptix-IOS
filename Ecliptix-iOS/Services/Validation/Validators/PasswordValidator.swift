//
//  PasswordValidator.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

import Foundation

struct PasswordValidator: FieldValidating {
    private static let minLength: Int = 6
    private static let maxLength: Int = 21
    private static let minCharClasses: Int = 2
    private static let minTotalEntropyBits: Double = 30
        
    func validate(_ value: String) -> (errors: [PasswordValidationError], suggestions: [PasswordValidationError]) {
        let validationRules: [(String) -> PasswordValidationError?] = [
            checkEmpty,
            checkTooShort,
            checkUpperCase,
            checkNonEnglishLetters
        ]
        
        let recommendations: [(String) -> PasswordValidationError?] = [
            checkNoDigit,
            checkTooLong,
            checkLeadingOrTrailingSpaces,
            checkTooSimple,
            checkTooCommon,
            checkSequentialPattern,
            checkExcessiveRepeats,
            checkInsufficientCharacterDiversity,
            checkContainsAppNameVariant
        ]

        var errors: [PasswordValidationError] = []

        for rule in validationRules {
            if let error = rule(value) {
                errors.append(error)
            }
        }
        if !errors.isEmpty {
            return (errors, [])
        }
        
        var suggestions: [PasswordValidationError] = []

        for rule in recommendations {
            if let suggestion = rule(value) {
                suggestions.append(suggestion)
            }
        }
        if !suggestions.isEmpty {
            return (errors, suggestions)
        }
        
        return ([], [])
    }
    
    // MARK: - Validation Rules

    private func checkEmpty(_ password: String) -> PasswordValidationError? {
        return password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .required : nil
    }

    private func checkTooShort(_ password: String) -> PasswordValidationError? {
        return password.count < Self.minLength ? .minLength(Self.minLength) : nil
    }
    
    private func checkUpperCase(_ password: String) -> PasswordValidationError? {
        return PasswordCharacterDiversity.upperCase(password) ? .noUppercase : nil
    }
    
    private func checkNonEnglishLetters(_ password: String) -> PasswordValidationError? {
        return PasswordCharacterDiversity.noNonEnglishLetters(password) ? .nonEnglishLetters : nil
    }

    private func checkTooLong(_ password: String) -> PasswordValidationError? {
        return password.count > Self.maxLength ? .maxLength(Self.maxLength) : nil
    }

    private func checkLeadingOrTrailingSpaces(_ password: String) -> PasswordValidationError? {
        return password.trimmingCharacters(in: .whitespacesAndNewlines) != password ? .noSpaces : nil
    }

    private func checkTooSimple(_ password: String) -> PasswordValidationError? {
        return self.calculateTotalShannonEntropy(password) < Self.minTotalEntropyBits ? .tooSimple : nil
    }

    private func checkTooCommon(_ password: String) -> PasswordValidationError? {
        return PasswordCommons.commonlyUsedPasswords.contains(password) ? .tooCommon : nil
    }
    
    private func checkNoDigit(_ password: String) -> PasswordValidationError? {
        return PasswordCharacterDiversity.noDigit(password) ? .noDigit : nil
    }

    private func checkSequentialPattern(_ password: String) -> PasswordValidationError? {
        return PasswordPatterns.isSequentialOrKeyboardPattern(password) ? .sequentialPattern : nil
    }

    private func checkExcessiveRepeats(_ password: String) -> PasswordValidationError? {
        return self.hasExcessiveRepeats(password) ? .repeatedChars : nil
    }

    private func checkInsufficientCharacterDiversity(_ password: String) -> PasswordValidationError? {
        return PasswordCharacterDiversity.lacksCharacterDiversity(password, minCharClasses: Self.minCharClasses) ? .lacksDiversity(requiredTypes: Self.minCharClasses) : nil
    }

    private func checkContainsAppNameVariant(_ password: String) -> PasswordValidationError? {
        return PasswordAppNameCheck.containsAppNameVariant(password) ? .containsAppName : nil
    }
    
    private func calculateTotalShannonEntropy(_ string: String) -> Double {
        guard !string.isEmpty else { return 0 }

        let totalLength = Double(string.count)
        var frequencyMap: [Character: Int] = [:]

        for char in string {
            frequencyMap[char, default: 0] += 1
        }

        let entropy = frequencyMap.values
            .map { count -> Double in
                let p = Double(count) / totalLength
                return -p * log2(p)
            }
            .reduce(0, +)

        return entropy * totalLength
    }
    
    private func hasExcessiveRepeats(_ s: String) -> Bool {
        guard s.count >= 4 else { return false }

        let chars = Array(s)
        for i in 0...(chars.count - 4) {
            if chars[i] == chars[i + 1],
               chars[i] == chars[i + 2],
               chars[i] == chars[i + 3] {
                return true
            }
        }

        return false
    }
}
