//
//  LanguageMenu.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 24.07.2025.
//

import SwiftUI

struct LanguageMenu: View {
    
    @EnvironmentObject var localizationService: LocalizationService
    private let secureStorageKey = try! ServiceLocator.shared.resolve(SecureStorageProviderProtocol.self)
    
    var body: some View {
        Menu {
            ForEach(SupportedLanguage.allCases, id: \.self) { language in
                Button {
                    localizationService.setLanguage(language) {
                        let result = self.secureStorageKey.setApplicationSettingsCultureAsync(culture: language.rawValue)
                        
                        switch result {
                        case .success:
                            print("Culture saved successfully")
                        case .failure(let error):
                            print("Failed to save culture: \(error)")
                        }
                    }
                } label: {
                    HStack {
                        Image(language.flagImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                        Text(language.displayName)
                            .foregroundStyle(.black)
                    }
                }
                .frame(minWidth: 60, maxWidth: 70)
            }
        } label: {
            HStack {
                Image(localizationService.currentLanguage.flagImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                Text(localizationService.currentLanguage.displayName)
                    .foregroundStyle(.black)
            }
        }
    }
}
