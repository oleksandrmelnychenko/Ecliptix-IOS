//
//  ChatOverviewItem.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 06.08.2025.
//


import SwiftUI

struct ChatOverviewItem: View {
    private var chatName: String
    private var lastMessage: String
    private var unreadMessagesCount: Int
    private var lastMessageDate: Date
    
    init(
        chatName: String,
        lastMessage: String,
        unreadMessagesCount: Int,
        lastMessageDate: Date
    ) {
        self.chatName = chatName
        self.lastMessage = lastMessage
        self.unreadMessagesCount = unreadMessagesCount
        self.lastMessageDate = lastMessageDate
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(self.chatName)
                    .bold(true)
                Text(self.lastMessage)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(Self.timeFormatter.string(from: lastMessageDate))
                   .font(.caption)
                   .foregroundColor(.gray)
                Text("\(self.unreadMessagesCount)")
                    .font(.caption2)
                    .padding(6)
                    .background(Circle().fill(Color.blue))
                    .foregroundColor(.white)
            }
            
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

#Preview {
    ChatOverviewItem(
        chatName: "Chat Name",
        lastMessage: "This is my last message",
        unreadMessagesCount: 200,
        lastMessageDate: Date())
}
