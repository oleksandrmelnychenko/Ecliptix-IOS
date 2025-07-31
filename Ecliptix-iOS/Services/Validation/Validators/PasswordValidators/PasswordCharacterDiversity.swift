//
//  PasswordCharacterDiversity.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 21.07.2025.
//

import Foundation

struct PasswordCharacterDiversity {
    private static let lowercaseRegex = try! NSRegularExpression(pattern: "[a-z]", options: [])
    private static let uppercaseRegex = try! NSRegularExpression(pattern: "[A-Z]", options: [])
    private static let digitRegex = try! NSRegularExpression(pattern: "\\d", options: [])
    private static let specialCharRegex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9]*$", options: [])
    private static let nonEnglishLetterRegex = try! NSRegularExpression(pattern: "[^A-Za-z\\W\\d_]", options: [])
    
    static func upperCase(_ s: String) -> Bool {
        let range = NSRange(location: 0, length: s.utf16.count)
        
        return uppercaseRegex.firstMatch(in: s, range: range) == nil
    }
    
    static func noDigit(_ s: String) -> Bool {
        let range = NSRange(location: 0, length: s.utf16.count)
        
        return digitRegex.firstMatch(in: s, range: range) == nil
    }
    
    static func noNonEnglishLetters(_ s: String) -> Bool {
        let range = NSRange(location: 0, length: s.utf16.count)
        
        return nonEnglishLetterRegex.firstMatch(in: s, options: [], range: range) != nil
    }
    
    static func lacksCharacterDiversity(_ s: String, minCharClasses: Int) -> Bool {
        return getCharacterClassCount(s) < minCharClasses
    }

    private static func getCharacterClassCount(_ s: String) -> Int {
        let range = NSRange(location: 0, length: s.utf16.count)
        var count = 0

        if lowercaseRegex.firstMatch(in: s, range: range) != nil { count += 1 }
        if uppercaseRegex.firstMatch(in: s, range: range) != nil { count += 1 }
        if digitRegex.firstMatch(in: s, range: range) != nil { count += 1 }
        if specialCharRegex.firstMatch(in: s, range: range) != nil { count += 1 }

        return count
    }
}
