//
//  PasswordCommons.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 21.07.2025.
//

struct PasswordCommons {
    static let commonlyUsedPasswords: Set<String> = {
        return Set(getTopCommonPasswords().map { $0.lowercased() })
    }()

    private static func getTopCommonPasswords() -> [String] {
        return [
            "123456",
            "password",
            "12345678",
            "123456789",
            "qwerty"
        ]
    }
}
