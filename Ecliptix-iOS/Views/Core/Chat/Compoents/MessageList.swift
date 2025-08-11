//
//  MessageList.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct MessageList: View {
    @Binding var messages: [ChatMessage]
    var onReply: (ChatMessage) -> Void = { _ in }
    var onForward: (ChatMessage) -> Void = { _ in }
    var onCopy: (ChatMessage) -> Void = { _ in }
    var onDelete: (ChatMessage) -> Void = { _ in }
    var onLongPressWithFrame: (ChatMessage, CGRect) -> Void = { _, _ in }
    var spaceName: String = "chatScroll"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { msg in
                        HStack {
                            if msg.isSentByUser { Spacer() }

                            MessageBubble(
                                message: msg,
                                onReply: onReply,
                                onForward: onForward,
                                onCopy: onCopy,
                                onDelete: onDelete,
                                spaceName: spaceName,
                                onLongPressWithFrame: onLongPressWithFrame
                            )

                            if !msg.isSentByUser { Spacer() }
                        }
                        .id(msg.id)
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) {
                if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
        .coordinateSpace(name: spaceName)
    }
}



#Preview {
    @Previewable @State var messages: [ChatMessage] = [
        .init(id: UUID(), text: "Привіт!", isSentByUser: false),
        .init(id: UUID(), text: "Привіт! Як справи?", isSentByUser: true)
    ]
    
    MessageList(
        messages: $messages,
        onReply: { _ in },
        onForward: { _ in },
        onCopy: { _ in },
        onDelete: { _ in }
    )
}
