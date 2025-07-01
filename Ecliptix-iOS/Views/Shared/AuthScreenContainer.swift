//
//  AuthScreenContainer.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 16.06.2025.
//

import SwiftUI

struct AuthScreenContainer<Content: View>: View {
    let content: Content
    let spacing: CGFloat
    let showLogo: Bool
    let showLicense: Bool
    
    @ObservedObject private var localization = ServiceLocator.shared.resolve(LocalizationService.self)

    init(spacing: CGFloat = 0, showLogo: Bool = true, showLicense: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.spacing = spacing
        self.showLogo = showLogo
        self.showLicense = showLicense
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                if showLogo == true {
                    HStack {
                        Spacer()
                        Image("EcliptixLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                        Text("Ecliptix")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.top, 25)
//                    .padding(.horizontal, 35)
                }
                
                VStack(alignment: .leading, spacing: spacing) {
                    content
                }
                .padding(.horizontal)
                .padding(.top, showLogo ? 20 : 100)
                
                if showLicense == true {
                    HStack {
                        Spacer()
                        Text("© Horizon Dynamics LLC 2025")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.top, 10)
                }
            }
            
            
            // Language Switcher Button
            Menu {
                ForEach(SupportedLanguage.allCases, id: \.self) { language in
                    Button {
                        localization.load(locale: language.code)
                    } label: {
                        Text("\(language.flagEmoji) \(language.code.components(separatedBy: "-").first?.uppercased() ?? "")")
                    }
                }
            } label: {
                Text("\(localization.currentLanguage.flagEmoji) \(localization.currentLanguage.code.components(separatedBy: "-").first?.uppercased() ?? "")")
                    .font(.title2)
                    .padding(8)
            }
            .padding(.top, 0)
            .padding(.trailing, 20)
        }
    }
}
