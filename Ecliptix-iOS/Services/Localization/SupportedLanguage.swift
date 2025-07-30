//
//  SupportedLanguage.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.06.2025.
//

import Foundation

enum SupportedLanguage: String, CaseIterable {
    case en = "en-US"
    case uk = "uk-UA"
    
    init?(code: String) {
        self.init(rawValue: code)
    }
    
    var flagImageName: String {
        switch self {
        case .en: return "usa_flag"
        case .uk: return "ukraine_flag"
        }
    }
    
    var code: String {
        self.rawValue
    }
    
    var displayName: String {
        switch self {
        case .en: return "EN"
        case .uk: return "UK"
        }
    }

    var next: SupportedLanguage {
        let all = Self.allCases
        if let currentIndex = all.firstIndex(of: self) {
            let nextIndex = (currentIndex + 1) % all.count
            return all[nextIndex]
        }
        return self
    }
    
    static func fromSystemLocale() -> SupportedLanguage {
        let systemLanguage = Locale.preferredLanguages.first ?? "en"
        for lang in SupportedLanguage.allCases {
            if systemLanguage.starts(with: lang.code.prefix(2)) {
                return lang
            }
        }
        return .en
    }
}
