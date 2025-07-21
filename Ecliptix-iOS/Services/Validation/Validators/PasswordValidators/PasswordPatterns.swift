//
//  PasswordPatterns.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 21.07.2025.
//

struct PasswordPatterns {
    private static let keyboardRows: [String] = [
        "qwertyuiop",
        "asdfghjkl",
        "zxcvbnm",
        "1234567890"
    ]

    static func isSequentialOrKeyboardPattern(_ s: String) -> Bool {
        guard s.count >= 4 else { return false }
        let lower = s.lowercased()
        let chars = Array(lower)

        for i in 0...(chars.count - 4) {
            let sub = String(chars[i..<i+4])
            if keyboardRows.contains(where: { $0.contains(sub) }) || isCharSequence(sub) {
                return true
            }
        }

        return false
    }

    private static func isCharSequence(_ sub: String) -> Bool {
        let chars = Array(sub)
        guard chars.count >= 2 else { return false }

        var ascending = true
        var descending = true

        for j in 1..<chars.count {
            if chars[j].asciiValue != chars[j - 1].asciiValue.map({ $0 + 1 }) {
                ascending = false
            }
            if chars[j].asciiValue != chars[j - 1].asciiValue.map({ $0 - 1 }) {
                descending = false
            }
        }

        return ascending || descending
    }
}
