//
//  PasswordStrengthType.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 04.08.2025.
//

enum PasswordStrengthType: String {
    case invalid
    case veryWeak
    case weak
    case good
    case strong
    case veryStrong
    
    var styleKey: String {
        return self.rawValue.prefix(1).uppercased() + self.rawValue.dropFirst()
    }
}
