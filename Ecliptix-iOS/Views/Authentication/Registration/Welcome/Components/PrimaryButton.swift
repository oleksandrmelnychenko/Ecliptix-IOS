//
//  NavigationCardButton.swift
//  Ecliptix-iOS-Views
//
//  Created by Oleksandr Melnechenko on 02.06.2025.
//

import SwiftUI

struct PrimaryButton: View {    
    let title: String
    let style: Style

    var body: some View {
        HStack {
            Spacer()

            Text(title)
                .font(.headline)
                .foregroundColor(style.foreground)

            Spacer()
        }
        .padding()
        .background(style.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(style.border ? style.foreground : .clear, lineWidth: style.border ? 1 : 0)
        )
    }
    
    enum Style {
        case light
        case dark

        var foreground: Color {
            switch self {
            case .light: return Color("Button.Dark")
            case .dark: return Color("Button.Light")
            }
        }

        var background: Color {
            switch self {
            case .light: return Color("Button.Light")
            case .dark: return Color("Button.Dark")
            }
        }

        var border: Bool {
            switch self {
            case .light: return false
            case .dark: return false
            }
        }
    }
}

#Preview {
    PrimaryButton(
        title: "Title",
        style: .dark
    )
    .padding()
}

#Preview {
    PrimaryButton(
        title: "Title",
        style: .light
    )
    .padding()
}
