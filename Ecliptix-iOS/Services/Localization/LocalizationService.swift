//
//  LocalizationService.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import Foundation
import UIKit

final class LocalizationService: ObservableObject {
    static let shared = LocalizationService()

    @Published private(set) var currentLanguage: SupportedLanguage = .en
    private var localizedData: [String: Any] = [:]

    private let userDefaultsKey = "SelectedLanguageCode"
    private let lastSeenSystemLanguageKey = "LastSeenSystemLanguageCode"
    
//    private init() {
//        // 1. Перевірка системної мови, встановленої в НАЛАШТУВАННЯХ додатку
//        let appLanguageCode = Bundle.main.preferredLocalizations.first ?? "en"
//        
//        // 2. Якщо мова підтримується — використовуємо її
//        if let lang = SupportedLanguage.allCases.first(where: { appLanguageCode.starts(with: $0.code.prefix(2)) }) {
//            self.currentLanguage = lang
//            setLanguage(lang, save: false) // ❗️НЕ зберігаємо в UserDefaults
//            return
//        }
//
//        // 3. Інакше — пробуємо збережену мову користувача
//        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
//           let savedLang = SupportedLanguage(rawValue: saved) {
//            self.currentLanguage = savedLang
//            setLanguage(savedLang)
//            return
//        }
//
//        // 4. Інакше — дефолтна системна мова
//        let systemLang = SupportedLanguage.fromSystemLocale()
//        self.currentLanguage = systemLang
//        setLanguage(systemLang)
//    }
    private init() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let savedLang = SupportedLanguage(rawValue: saved) {
            self.currentLanguage = savedLang
            load(locale: savedLang.code)
        } else {
            let systemLang = SupportedLanguage.fromSystemLocale()
            self.currentLanguage = systemLang
            load(locale: systemLang.code)
        }
    }

    private func load(locale: String) {
        guard let lang = SupportedLanguage(rawValue: locale) else { return }
        guard
            let url = Bundle.main.url(forResource: locale, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            print("Failed to load localization for locale: \(locale)")
            return
        }

        DispatchQueue.main.async {
            self.localizedData = json
            self.currentLanguage = lang
        }
    }
    
    func setLanguage(_ language: SupportedLanguage, onCultureChanged: (() -> Void)? = nil) {
        UserDefaults.standard.set(language.code, forKey: userDefaultsKey)
        UserDefaults.standard.synchronize()

        load(locale: language.code)

        DispatchQueue.main.async {
            onCultureChanged?()
        }
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
    
    func checkIfSystemLanguageChanged() -> SupportedLanguage? {
        let currentSystemCode = Bundle.main.preferredLocalizations.first ?? "en"

        guard let systemLang = SupportedLanguage.allCases.first(where: { currentSystemCode.starts(with: $0.code.prefix(2)) }) else {
            return nil
        }

        let lastSeenCode = UserDefaults.standard.string(forKey: lastSeenSystemLanguageKey)

        // Якщо мова в системі змінилася з моменту останнього запуску
        if systemLang.code != lastSeenCode {
            // Зберігаємо нову
            UserDefaults.standard.set(systemLang.code, forKey: lastSeenSystemLanguageKey)

            // Показуємо тільки якщо вона ≠ з поточною в додатку
            return systemLang != currentLanguage ? systemLang : nil
        }

        return nil
    }
}

extension String {
    var localized: String {
        let localizationService = try! ServiceLocator.shared.resolve(LocalizationService.self)
        return localizationService.localizedString(forKey: self)
    }
}
