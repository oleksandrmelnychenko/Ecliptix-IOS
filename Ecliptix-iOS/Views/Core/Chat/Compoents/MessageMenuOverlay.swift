//
//  MessageMenuOverlay.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 11.08.2025.
//


import SwiftUI

struct MessageMenuOverlay: View {
    let message: ChatMessage
    var onReply: (ChatMessage) -> Void
    var onForward: (ChatMessage) -> Void
    var onCopy: (ChatMessage) -> Void
    var onDelete: (ChatMessage) -> Void
    var isLastInGroup: Bool = false
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 8) {
                TextMessage(message: message, isLastInGroup: isLastInGroup)
                    .scaleEffect(1.05)
                    .shadow(radius: 4)

                HStack {
                    actionButton("Reply", systemImage: "arrowshape.turn.up.left") {
                        onReply(message); onDismiss()
                    }
                    actionButton("Forward", systemImage: "arrowshape.turn.up.right") {
                        onForward(message); onDismiss()
                    }
                    actionButton("Copy", systemImage: "doc.on.doc") {
                        onCopy(message); onDismiss()
                    }
                    actionButton("Delete", systemImage: "trash", color: .red) {
                        onDelete(message); onDismiss()
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            .padding()
        }
        .transition(.opacity.combined(with: .scale))
    }

    private func actionButton(_ title: String, systemImage: String, color: Color = .primary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: systemImage)
                Text(title).font(.caption2)
            }
            .foregroundColor(color)
            .padding(.horizontal, 8)
        }
    }
}

#Preview {
    MessageMenuOverlay(
        message: ChatMessage(id: UUID(), text: "Demo text", isSentByUser: false),
        onReply: { _ in },
        onForward: { _ in },
        onCopy: { _ in },
        onDelete: { _ in },
        onDismiss: {})
}
