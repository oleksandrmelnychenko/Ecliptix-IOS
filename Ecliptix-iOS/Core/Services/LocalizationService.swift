//
//  LocalizationService.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import Foundation

final class LocalizationService: ObservableObject {
    static let shared = LocalizationService()
    
    private var localizedData: [String: Any] = [:]
    private(set) var currentLocale: String = "en-US"

    private init() {
        load(locale: currentLocale)
    }

    func load(locale: String) {
        guard let url = Bundle.main.url(forResource: locale, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("Failed to load localization for locale: \(locale)")
            return
        }
        self.localizedData = json
        self.currentLocale = locale
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
        LocalizationService.shared.localizedString(forKey: self)
    }
}
