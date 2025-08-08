//
//  MessageBubble.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    var onReply: (ChatMessage) -> Void
    var onForward: (ChatMessage) -> Void
    var onCopy: (ChatMessage) -> Void
    var onDelete: (ChatMessage) -> Void

    var body: some View {
        TextMessage(message: message)
            .contextMenu {
                Button {
                    onReply(message)
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                }

                Button {
                    onForward(message)
                } label: {
                    Label("Forward", systemImage: "arrowshape.turn.up.right")
                }

                Button {
                    onCopy(message)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                Button(role: .destructive) {
                    onDelete(message)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }
}
