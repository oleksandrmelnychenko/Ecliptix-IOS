//
//  PasswordCharacterDiversity.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 21.07.2025.
//

import Foundation

struct PasswordCharacterDiversity {
    private static let lowercaseRegex = try! NSRegularExpression(pattern: "[a-z]")
    private static let uppercaseRegex = try! NSRegularExpression(pattern: "[A-Z]")
    private static let digitRegex = try! NSRegularExpression(pattern: "\\d")
    private static let alphanumericOnlyRegex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9]*$")
    private static let nonEnglishLetterRegex = try! NSRegularExpression(pattern: "[^A-Za-z\\W\\d_]")

    static func upperCase(_ s: String) -> Bool {
        match(uppercaseRegex, in: s) == nil
    }

    static func noDigit(_ s: String) -> Bool {
        match(digitRegex, in: s) == nil
    }

    static func noNonEnglishLetters(_ s: String) -> Bool {
        match(nonEnglishLetterRegex, in: s) != nil
    }

    static func lacksCharacterDiversity(_ s: String, minCharClasses: Int) -> Bool {
        getCharacterClassCount(s) < minCharClasses
    }

    static func containsOnlyAlphanumeric(_ s: String) -> Bool {
        match(alphanumericOnlyRegex, in: s) != nil
    }

    static func containsAny(fromSpecialChars allowed: String, in s: String) -> Bool {
        let escaped = NSRegularExpression.escapedPattern(for: allowed)
        let pattern = "[\(escaped)]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        return match(regex, in: s) != nil
    }

    static func containsOnlyAllowedCharacters(_ s: String, allowedSpecials: String) -> Bool {
        let escaped = NSRegularExpression.escapedPattern(for: allowedSpecials)
        let pattern = "^[a-zA-Z0-9\(escaped)]*$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        return match(regex, in: s) != nil
    }

    private static func getCharacterClassCount(_ s: String) -> Int {
        var count = 0
        if match(lowercaseRegex, in: s) != nil { count += 1 }
        if match(uppercaseRegex, in: s) != nil { count += 1 }
        if match(digitRegex, in: s) != nil { count += 1 }
        if !containsOnlyAlphanumeric(s) { count += 1 }
        return count
    }

    private static func match(_ regex: NSRegularExpression, in s: String) -> NSTextCheckingResult? {
        let range = NSRange(s.startIndex..<s.endIndex, in: s)
        return regex.firstMatch(in: s, range: range)
    }
}
