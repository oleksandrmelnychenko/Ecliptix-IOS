//
//  MessageBubble.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//

import SwiftUI

private struct BubbleFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    var onReply: (ChatMessage) -> Void
    var onForward: (ChatMessage) -> Void
    var onCopy: (ChatMessage) -> Void
    var onDelete: (ChatMessage) -> Void
    var spaceName: String = "chatScroll"
    var onLongPressWithFrame: (ChatMessage, CGRect) -> Void = { _, _ in }

    @State private var frameInScroll: CGRect = .zero

    var body: some View {
        TextMessage(message: message)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            frameInScroll = geo.frame(in: .named(spaceName))
                        }
                        .onChange(of: geo.frame(in: .named(spaceName))) { new in
                            frameInScroll = new
                        }
                }
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onLongPressGesture(minimumDuration: 0.3) {
                onLongPressWithFrame(message, frameInScroll)
            }
    }
}






#Preview("Incoming") {
    MessageBubble(
        message: ChatMessage(id: UUID(), text: "Demo text", isSentByUser: false),
        onReply: { _ in },
        onForward: { _ in },
        onCopy: { _ in },
        onDelete: { _ in }
    )
}

#Preview("Outgoing") {
    MessageBubble(
        message: ChatMessage(id: UUID(), text: "Demo text", isSentByUser: true),
        onReply: { _ in },
        onForward: { _ in },
        onCopy: { _ in },
        onDelete: { _ in }
    )
}

#Preview("Both") {
    VStack(spacing: 12) {
        HStack {
            MessageBubble(
                message: ChatMessage(id: UUID(), text: "Demo text", isSentByUser: false),
                onReply: { _ in }, onForward: { _ in }, onCopy: { _ in }, onDelete: { _ in }
            )
            Spacer()
        }
        HStack {
            Spacer()
            MessageBubble(
                message: ChatMessage(id: UUID(), text: "Demo text", isSentByUser: true),
                onReply: { _ in }, onForward: { _ in }, onCopy: { _ in }, onDelete: { _ in }
            )
        }
    }
}

