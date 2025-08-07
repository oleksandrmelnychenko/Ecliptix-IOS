//
//  KeyButton.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 16.06.2025.
//


import SwiftUI

struct KeyButton: View {
    var title: String? = nil
    var systemImage: String? = nil
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }

            action()
        }) {
            Group {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.title)
                } else if let title = title {
                    Text(title)
                        .font(.title)
                }
            }
            .frame(width: 70, height: 70)
            .scaleEffect(isPressed ? 0.85 : 1.0)
            .foregroundStyle(Color("LightButton.ForegroundColor"))
            .background(Color("LightButton.BackgroundColor"))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color("DarkButton.BackgroundColor"), lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
    }
}


#Preview {
    KeyButton(
        title: "1",
        systemImage: nil,
        action: {
        print("Button was pressed")
    })
}
