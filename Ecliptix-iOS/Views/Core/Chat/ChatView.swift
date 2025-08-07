//
//  ChatView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 05.08.2025.
//

import SwiftUI

struct ChatView: View {
    let chatName: String
    
    @State private var messageText: String = ""
    
    @State private var messages: [ChatMessage] = [
        .init(id: UUID(), text: "Привіт!", isSentByUser: false),
        .init(id: UUID(), text: "Привіт! Як справи?", isSentByUser: true)
    ]
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isSentByUser {
                                    Spacer()
                                }
                                
                                Text(message.text)
                                    .padding(10)
                                    .background(message.isSentByUser ? Color.blue : Color.gray.opacity(0.3))
                                    .foregroundColor(message.isSentByUser ? .white : .black)
                                    .cornerRadius(12)
                                    .frame(maxWidth: 250, alignment: message.isSentByUser ? .trailing : .leading)
                                
                                if !message.isSentByUser {
                                    Spacer()
                                }
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            Divider()
            
            HStack(spacing: 8) {
                Button {
                    print("Add attachment tapped")
                } label: {
                    Image(systemName: "plus.circle")
                       .font(.system(size: 22))
                       .foregroundColor(.blue)
                }

                
                TextField("Message...", text: $messageText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .disableAutocorrection(true)

                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .rotationEffect(.degrees(45))
                        .foregroundColor(.blue)
                        .font(.system(size: 22))
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .navigationTitle(chatName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
    
    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        messages.append(.init(id: UUID(), text: trimmed, isSentByUser: true))
        messageText = ""
    }
}

struct ChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isSentByUser: Bool
}

#Preview {
    ChatView(chatName: "Roman")
}
