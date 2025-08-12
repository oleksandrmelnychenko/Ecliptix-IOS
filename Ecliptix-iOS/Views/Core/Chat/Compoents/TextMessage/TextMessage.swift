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
    let isLastInGroup: Bool
    private let r: CGFloat = 16

    private var fill: Color { message.isSentByUser ? .blue : .white }
    private var text: Color { message.isSentByUser ? .white : .primary }
    private var timeText: String { "20:20" }

    var body: some View {
        Text(message.text)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(text)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
//            .padding(.bottom, isLastInGroup ? 6 : 0) // трішки місця під хвіст + час
//            .overlay(
//                Text(timeText)
//                    .font(.caption2)
//                    .foregroundColor(text.opacity(0.9))
//                    .padding(.bottom, isLastInGroup ? 10 : 6)
//                    .padding(.trailing, 6), alignment: .bottomTrailing
//            )
            .background(
                ChatBubbleShape(isFromCurrentUser: message.isSentByUser,
                                showTail: isLastInGroup,
                                cornerRadius: r)
                    .fill(fill)
            )
            .frame(maxWidth: UIScreen.main.bounds.width * 0.9, alignment: message.isSentByUser ? .trailing : .leading)
            .contentShape(Rectangle())
//            .drawingGroup() // згладження кривих хвоста (опційно)
    }
}

#Preview("Income") {
    TextMessage(
        message: .init(id: UUID(), text: "Hello, world!", isSentByUser: false), isLastInGroup: true)
}

#Preview("Outcome") {
    TextMessage(
        message: .init(id: UUID(), text: "Hi", isSentByUser: true), isLastInGroup: true)
    .padding()
}
