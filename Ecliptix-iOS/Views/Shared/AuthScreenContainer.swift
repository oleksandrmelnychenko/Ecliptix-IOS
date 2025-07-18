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
        VStack(spacing: 0) {
            if showLogo {
                HStack {
                    Spacer()
                    Image("EcliptixLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                    Spacer()
                }
                .padding(.top, 15)
            }

            VStack(alignment: .leading, spacing: spacing) {
                content
            }
            .padding(.horizontal)
            .padding(.top, showLogo ? 20 : 100)

            Spacer(minLength: 0)

            if showLicense {
                HStack {
                    Spacer()
                    Text("© Horizon Dynamics LLC 2025")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
        }
    }
}
