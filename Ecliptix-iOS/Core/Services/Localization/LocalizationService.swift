//
//  LocalizationService.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import Foundation

final class LocalizationService: ObservableObject {
    static let shared = LocalizationService()
    
    @Published private(set) var languageChanged = UUID()
    
    private var localizedData: [String: Any] = [:]
    private(set) var currentLanguage: SupportedLanguage = .en

    private init() {
        load(locale: currentLanguage.code)
    }
    
    func load(locale: String) {
        guard let lang = SupportedLanguage(rawValue: locale) else { return }
        guard
            let url = Bundle.main.url(forResource: locale, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            print("Failed to load localization for locale: \(locale)")
            return
        }
        
        self.localizedData = json
        self.currentLanguage = lang
        self.languageChanged = UUID()
    }
    
    func toggleLanguage() {
        let next = currentLanguage.next
        load(locale: next.code)
    }

    func localizedString(forKey key: String) -> String {
        let keys = key.components(separatedBy: ".")
        var currentLevel: Any? = localizedData
        
        for part in keys {
            if let dict = currentLevel as? [String: Any] {
                currentLevel = dict[part]
            } else {
                return key
            }
        }

        return currentLevel as? String ?? key
    }
}

extension String {
    var localized: String {
        let localizationService = ServiceLocator.shared.resolve(LocalizationService.self)
        return localizationService.localizedString(forKey: self)
    }
}
