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
                            .buttonStyle(.plain)
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

#Preview {
    ChatsOverviewView()
}
