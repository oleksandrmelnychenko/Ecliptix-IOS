//
//  ChatTitleButton.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ChatTitleButton: View {
    let title: String
    let subtitle: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                    .bold()
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

#Preview {
    ChatTitleButton(
        title: "Demo Title",
        subtitle: "demo subtitles",
        onTap: {
            print("Chat title was tapped")
        }
    )
}
