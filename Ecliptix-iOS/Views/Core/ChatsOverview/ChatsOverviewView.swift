//
//  ChatsOverviewView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 05.08.2025.
//

import SwiftUI

struct ChatsOverviewView: View {
    @State private var showSearchBar = true
    @State private var searchText = ""
    @State private var previousScrollOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(0..<20) { index in
                            NavigationLink(
                                destination: ChatView(chatName: "Chat \(index)")
                            ) {
                                ChatOverviewItem(
                                    chatName: "Chat \(index)",
                                    lastMessage: "Message from chat \(index)",
                                    unreadMessagesCount: index,
                                    lastMessageDate: Date()
                                )
                            }
                            .buttonStyle(.plain) // прибирає синє підсвічування
                        }
                    }
                    .padding(.top)
                }
                .navigationBarTitleDisplayMode(.inline)
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Edit")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "square.and.pencil")
                }
            }
            .navigationBarHidden(false)
        }
    }
}

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
    ChatsOverviewView()
}
