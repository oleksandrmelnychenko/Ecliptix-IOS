//
//  SupportedLanguage.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.06.2025.
//

enum SupportedLanguage: String, CaseIterable {
    case en = "en-US"
    case uk = "uk-UA"
    
    var flagEmoji: String {
        switch self {
        case .en: return "🇬🇧"
        case .uk: return "🇺🇦"
        }
    }
    
    var code: String {
        self.rawValue
    }

    var next: SupportedLanguage {
        let all = Self.allCases
        if let currentIndex = all.firstIndex(of: self) {
            let nextIndex = (currentIndex + 1) % all.count
            return all[nextIndex]
        }
        return self
    }
}
