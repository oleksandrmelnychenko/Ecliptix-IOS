//
//  ChatView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 05.08.2025.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    
    let chatName: String

    // Attachments state
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var showDocumentPicker = false
    @State private var selectedDocumentURL: URL?

    // Reply / menu state
    @State private var replyingTo: ChatMessage?
    @State private var menuMessage: ChatMessage? = nil
    
    @State private var menuTarget: (message: ChatMessage, frame: CGRect)? = nil
    private let scrollSpace = "chatScroll"

    // Chat state
    @State private var showChatInfo = false
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = [
        .init(id: UUID(), text: "Hi!", isSentByUser: false),
        .init(id: UUID(), text: "Hi! How are you?", isSentByUser: true),
//        .init(id: UUID(), text: "Привіт! 2", isSentByUser: false),
//        .init(id: UUID(), text: "Привіт! Як справи? 2", isSentByUser: true),
//        .init(id: UUID(), text: "Привіт! 3", isSentByUser: false),
//        .init(id: UUID(), text: "Привіт! Як справи? 3", isSentByUser: true),
//        .init(id: UUID(), text: "Привіт! 4", isSentByUser: false),
//        .init(id: UUID(), text: "Привіт! Як справи? 4", isSentByUser: true),
//        .init(id: UUID(), text: "Привіт! 5", isSentByUser: false),
//        .init(id: UUID(), text: "Привіт! Як справи? 5", isSentByUser: true),
//        .init(id: UUID(), text: "Привіт! 6", isSentByUser: false),
//        .init(id: UUID(), text: "Привіт! Як справи? 6", isSentByUser: true),
//        .init(id: UUID(), text: "Привіт! 7", isSentByUser: false),
//        .init(id: UUID(), text: "Привіт! Як справи? 7", isSentByUser: true),
    ]

    var body: some View {
        ZStack(alignment: .top) {
            ChatHeader(
                chatName: chatName,
                onBack: {
                    dismiss()
                },
                onInfo: {
                    showChatInfo = true
                }
            )
            .zIndex(10)
            
            VStack(spacing: 0) {
                MessageList(
                    messages: $messages,
                    onLongPressWithFrame: { msg, frame in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            menuTarget = (msg, frame)
                        }
                    },
                    spaceName: scrollSpace
                )

                Divider()

                if let replying = replyingTo {
                    ReplyPreview(message: replying) { replyingTo = nil }
                }

                InputBar(
                    text: $messageText,
                    onSend: sendMessage,
                    onChoosePhoto: { showPhotoPicker = true },
                    onTakePhoto: { showCamera = true },
                    onAttachFile: { showDocumentPicker = true }
                )
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
            }
            .padding(.top, 30)


            if let t = menuTarget {
                ZStack {
                    Color.clear
                        .background(.ultraThinMaterial)
                        .overlay(Color.black.opacity(0.08))
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.spring()) { menuTarget = nil } }

                    HStack {
                        if (t.message.isSentByUser) {
                            Spacer()
                        }
                        
                        VStack {
                            TextMessage(message: t.message, isLastInGroup: false)
                                .scaleEffect(1.05)
                                .shadow(radius: 4)
                            
                            Spacer()
                            
                            MessageActionMenu(
                                onReply:  { replyingTo = t.message; menuTarget = nil },
                                onForward:{ forward(t.message);     menuTarget = nil },
                                onCopy:   { UIPasteboard.general.string = t.message.text; menuTarget = nil },
                                onDelete: { delete(t.message);      menuTarget = nil },
                                onDismiss:{ withAnimation(.spring()) { menuTarget = nil } }
                            )
                        }
                        
                        if (!t.message.isSentByUser) {
                            Spacer()
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showChatInfo) { ChatInfoView(chatName: chatName) }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto)
        .sheet(isPresented: $showCamera) { Text("Camera not implemented") }
        .fileImporter(isPresented: $showDocumentPicker, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let url):
                selectedDocumentURL = url
                print("Selected document: \(url)")
            case .failure(let error):
                print("Document selection error: \(error.localizedDescription)")
            }
        }
        .background(
            Image("ChatBackground")
                .resizable(resizingMode: .tile)
                .interpolation(.none)
        )
    }

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(.init(id: UUID(), text: trimmed, isSentByUser: true))
        messageText = ""
        replyingTo = nil
    }

    private func forward(_ msg: ChatMessage) {
        print("Forward: \(msg.text)")
    }

    private func delete(_ msg: ChatMessage) {
        messages.removeAll { $0.id == msg.id }
    }
}

#Preview {
    ChatView(chatName: "Roman")
}


struct ReplyPreview: View {
    let message: ChatMessage
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Rectangle().fill(Color.blue).frame(width: 3).cornerRadius(1.5)
            VStack(alignment: .leading, spacing: 2) {
                Text("Replying to").font(.caption).foregroundColor(.gray)
                Text(message.text).font(.subheadline).lineLimit(1)
            }
            Spacer()
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
    }
}


