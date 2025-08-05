//
//  PasswordStrengthEstimator.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 04.08.2025.
//

import Foundation

struct PasswordStrengthEstimator {
    static func estimate(password: String) -> PasswordStrengthType {
        let (error, recommendations) = PasswordValidator().validate(password)

        if !error.isEmpty {
            print("Password strength: \(PasswordStrengthType.invalid.rawValue) (due to error: \(error.first!.message))")
            return password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .invalid : .veryWeak
        }

        var score = 0

        switch password.count {
        case 12...: score += 4
        case 9...:  score += 3
        case 7...:  score += 2
        case 6...:  score += 1
        default:    score += 0
        }

        let variety = characterClassCount(password)
        if variety >= 2 { score += 2 }
        if variety >= 3 { score += 1 }
        if variety == 4 { score += 1 }

        score -= recommendations.count

        let strength: PasswordStrengthType = {
            switch score {
            case ...2: return .weak
            case ...4: return .good
            case ...6: return .strong
            default:   return .veryStrong
            }
        }()

        print("Password strength: \(strength), Score=\(score), Variety=\(variety), RecommendationsCount=\(recommendations.count)")
        return strength
    }

    private static func characterClassCount(_ password: String) -> Int {
        var count = 0
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { count += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { count += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil     { count += 1 }
        if password.rangeOfCharacter(from: CharacterSet.punctuationCharacters.union(.symbols)) != nil {
            count += 1
        }
        return count
    }
}
