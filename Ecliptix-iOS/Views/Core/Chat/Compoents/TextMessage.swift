//
//  TextMessage.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct TextMessage: View {
    let message: ChatMessage
    private let r: CGFloat = 16

    private var fill: Color { message.isSentByUser ? .blue : Color.gray.opacity(0.25) }
    private var text: Color { message.isSentByUser ? .white : .primary }

    var body: some View {
        Text(message.text)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .foregroundColor(text)
            .background(fill)
            .mask(RoundedRectangle(cornerRadius: r, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: r, style: .continuous).stroke(fill, lineWidth: 0.75))
            .frame(maxWidth: 260, alignment: message.isSentByUser ? .trailing : .leading)
    }
}

#Preview {
    TextMessage(
        message: .init(id: UUID(), text: "Hello, world!", isSentByUser: true))
}
