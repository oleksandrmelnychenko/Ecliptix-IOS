//
//  PasswordValidator.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

import Foundation

struct PasswordValidator: FieldValidating {
    private static let minLength: Int = 8
    private static let maxLength: Int = 128
    private static let minCharClasses: Int = 3
    private static let minTotalEntropyBits: Double = 50
    
    func validate(_ value: String) -> [PasswordValidationError] {
        let rules: [(String) -> PasswordValidationError?] = [
            checkEmpty,
            checkTooShort,
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

        for rule in rules {
            if let error = rule(value) {
                errors.append(error)
            }
        }

        return errors
    }
    
    // MARK: - Validation Rules

    private func checkEmpty(_ password: String) -> PasswordValidationError? {
        return password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .empty : nil
    }

    private func checkTooShort(_ password: String) -> PasswordValidationError? {
        return password.count < Self.minLength ? .tooShort(Self.minLength) : nil
    }

    private func checkTooLong(_ password: String) -> PasswordValidationError? {
        return password.count > Self.maxLength ? .tooLong(Self.maxLength) : nil
    }

    private func checkLeadingOrTrailingSpaces(_ password: String) -> PasswordValidationError? {
        return password.trimmingCharacters(in: .whitespacesAndNewlines) != password ? .leadingOrTrailingSpaces : nil
    }

    private func checkTooSimple(_ password: String) -> PasswordValidationError? {
        return self.calculateTotalShannonEntropy(password) < Self.minTotalEntropyBits ? .tooSimple : nil
    }

    private func checkTooCommon(_ password: String) -> PasswordValidationError? {
        return PasswordCommons.commonlyUsedPasswords.contains(password) ? .tooCommon : nil
    }

    private func checkSequentialPattern(_ password: String) -> PasswordValidationError? {
        return PasswordPatterns.isSequentialOrKeyboardPattern(password) ? .sequentialPattern : nil
    }

    private func checkExcessiveRepeats(_ password: String) -> PasswordValidationError? {
        return self.hasExcessiveRepeats(password) ? .excessiveRepeats : nil
    }

    private func checkInsufficientCharacterDiversity(_ password: String) -> PasswordValidationError? {
        return PasswordCharacterDiversity.lacksCharacterDiversity(password, minCharClasses: Self.minCharClasses) ? .insufficientCharacterDiversity(requiredTypes: Self.minCharClasses) : nil
    }

    private func checkContainsAppNameVariant(_ password: String) -> PasswordValidationError? {
        return PasswordAppNameCheck.containsAppNameVariant(password) ? .containsAppNameVariant : nil
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
