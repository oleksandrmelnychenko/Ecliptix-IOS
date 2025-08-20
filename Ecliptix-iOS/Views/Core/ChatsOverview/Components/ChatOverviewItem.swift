//
//  ChatOverviewItem.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 06.08.2025.
//


import SwiftUI

struct ChatOverviewItem: View {
    private let chat: Chat
    
    init(chat: Chat) {
        self.chat = chat
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(self.chat.name)
                    .bold(true)
                Text(self.chat.lastMessage)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(Self.timeFormatter.string(from: self.chat.lastDate))
                   .font(.caption)
                   .foregroundColor(.gray)
                Text("\(self.chat.unread)")
                    .font(.caption2)
                    .padding(6)
                    .background(Circle().fill(Color.blue))
                    .foregroundColor(.white)
            }
            
        }
    }
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

#Preview {
    let demoChat = Chat(id: 1, name: "Chat Name", lastSeenOnline: "last seen recently", lastMessage: "This is my last message", unread: 200, lastDate: Date())
    
    ChatOverviewItem(chat: demoChat)
}
