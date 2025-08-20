//
//  ChatRow.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI

struct ChatRow: View {
    let chat: Chat
    let mode: ChatsMode
    let isSelected: Bool
    let onToggleSelect: () -> Void

    var body: some View {
        if mode == .selecting {
            HStack(spacing: 12) {
                Button(action: onToggleSelect) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                ChatOverviewItem(chat: chat)
            }
        } else {
            NavigationLink(destination: ChatView(chatName: chat.name, chatSubtitle: chat.lastSeenOnline)) {
                ChatOverviewItem(chat: chat)
                    .frame(maxWidth: .infinity, alignment: .leading) 
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    @Previewable @State var mode: ChatsMode = .selecting
    var chat = Chat(id: 1, name: "Demo chat", lastSeenOnline: "last seen recently", lastMessage: "This is a demo message", unread: 100,    lastDate: Date())
    
    ChatRow(
        chat: chat,
        mode: mode,
        isSelected: true,
        onToggleSelect: {})
}
