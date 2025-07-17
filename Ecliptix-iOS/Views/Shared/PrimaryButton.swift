//
//  NavigationCardButton.swift
//  Ecliptix-iOS-Views
//
//  Created by Oleksandr Melnechenko on 02.06.2025.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: {
            if isEnabled && !isLoading {
                action()
            }
        }) {
            HStack {
                Spacer()

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foreground.opacity(isEnabled ? 1 : 0.5)))
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(style.foreground.opacity(isEnabled ? 1 : 0.5))
                }

                Spacer()
            }
            .font(.subheadline)
            .padding()
            .background(style.background.opacity(isEnabled ? 1 : 0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        style.border ? style.foreground.opacity(isEnabled ? 1 : 0.5) : .clear,
                        lineWidth: style.border ? 1 : 0
                    )
            )
        }
        .disabled(!isEnabled || isLoading)
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
    HStack {
        PrimaryButton(
            title: "Account recovery",
            isEnabled: true,
            isLoading: false,
            style: .dark,
            action: {
                print("Button pressed!")
            }
        )
        .padding()
        
        PrimaryButton(
            title: "Continue",
            isEnabled: true,
            isLoading: true,
            style: .light,
            action: {
                print("Button pressed!")
            }
        )
    }
}

#Preview {
    PrimaryButton(
        title: "Continue",
        isEnabled: true,
        isLoading: true,
        style: .light,
        action: {
            print("Button pressed!")
        }
    )
}
