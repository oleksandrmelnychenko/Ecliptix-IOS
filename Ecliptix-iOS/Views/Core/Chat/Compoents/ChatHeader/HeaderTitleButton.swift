//
//  ChatTitleButton.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI

struct HeaderTitleButton: View {
    let title: String
    let subtitle: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                    .bold()
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

#Preview {
    HeaderTitleButton(
        title: "Demo Title",
        subtitle: "demo subtitles",
        action: {
            print("Chat title was tapped")
        }
    )
}
