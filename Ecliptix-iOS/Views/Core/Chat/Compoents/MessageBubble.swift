//
//  MessageBubble.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    var spaceName: String = "chatScroll"
    var isLastInGroup: Bool = true
    var onLongPressWithFrame: (ChatMessage, CGRect) -> Void = { _, _ in }

    @State private var frameInScroll: CGRect = .zero

    var body: some View {
        TextMessage(message: message, isLastInGroup: isLastInGroup)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            frameInScroll = geo.frame(in: .named(spaceName))
                        }
                        .onChange(of: geo.frame(in: .named(spaceName))) { _, new in
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
    MessageBubble(message: ChatMessage(id: UUID(), text: "Demo text", isSentByUser: false))
}

#Preview("Outgoing") {
    MessageBubble(message: ChatMessage(id: UUID(), text: "Demo text", isSentByUser: true))
}

#Preview("Both") {
    VStack(spacing: 12) {
        HStack {
            MessageBubble(message: ChatMessage(id: UUID(), text: "Demo text", isSentByUser: false))
            Spacer()
        }
        HStack {
            Spacer()
            MessageBubble(message: ChatMessage(id: UUID(), text: "Demo text", isSentByUser: true))
        }
    }
}

