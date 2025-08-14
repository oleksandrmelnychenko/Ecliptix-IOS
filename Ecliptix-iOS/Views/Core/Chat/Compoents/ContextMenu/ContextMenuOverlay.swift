//
//  ContextMenuOverlay.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 12.08.2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ContextMenuOverlay: View {
    @Binding var textMessage: TextMessage
    var onReply: (ChatMessage) -> Void
    var onForward: (ChatMessage) -> Void
    var onCopy: (ChatMessage) -> Void
    var onDelete: (ChatMessage) -> Void
    var onEdit: ((ChatMessage) -> Void)?

    var anchored: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            if !anchored { Spacer() }

            HStack {
                if textMessage.message.isSentByUser {
                    Spacer()
                    textMessage
                        .shadow(radius: 6, y: 3)
                        .padding(.trailing, 16)
                } else {
                    textMessage
                        .shadow(radius: 6, y: 3)
                        .padding(.leading, 16)
                    Spacer()
                }
            }

            HStack {
                if textMessage.message.isSentByUser {
                    Spacer()
                    MessageActionMenu(
                        status: Text("read today at 18:00"),
                        onReply:  { onReply(textMessage.message) },
                        onForward:{ onForward(textMessage.message) },
                        onCopy:   { onCopy(textMessage.message) },
                        onDelete: { onDelete(textMessage.message) },
                        onDismiss: { },
                        onEdit: {
                            if let handler = self.onEdit {
                                handler(textMessage.message)
                            } else {
                                print("On Edit is not implemented")
                            }
                        }
                    )
                    .padding(.trailing, 16)
                } else {
                    MessageActionMenu(
                        onReply:  { onReply(textMessage.message) },
                        onForward:{ onForward(textMessage.message) },
                        onCopy:   { UIPasteboard.general.string = textMessage.message.text },
                        onDelete: { onDelete(textMessage.message) },
                        onDismiss: { }
                    )
                    .padding(.leading, 16)
                    Spacer()
                }
            }
        }
    }
}



#Preview("Outcome") {
    @Previewable @State var textMessage: TextMessage = {
        let now = Date()
        let msg = ChatMessage(
            text: "Preview bubble with context menu",
            isSentByUser: true,
            createdAt: now,
            updatedAt: now
        )
        let textMessage = TextMessage(message: msg, isLastInGroup: true)
        return textMessage
    }()

    HStack {
        Spacer()
        
        ContextMenuOverlay(
            textMessage: $textMessage,
            onReply:  { _ in },
            onForward:{ _ in },
            onCopy:   { _ in },
            onDelete: { _ in }
        )
    }
}

#Preview("Income") {
    @Previewable @State var textMessage: TextMessage = {
        let now = Date()
        let msg = ChatMessage(
            text: "Preview bubble with context menu",
            isSentByUser: true,
            createdAt: now,
            updatedAt: now
        )
        let textMessage = TextMessage(message: msg, isLastInGroup: true)
        return textMessage
    }()

    HStack {
        ContextMenuOverlay(
            textMessage: $textMessage,
            onReply:  { _ in },
            onForward:{ _ in },
            onCopy:   { _ in },
            onDelete: { _ in }
        )
        
        Spacer()
    }
}
