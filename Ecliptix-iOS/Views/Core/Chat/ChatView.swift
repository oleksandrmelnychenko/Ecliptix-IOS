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
        .init(id: UUID(), text: "Привіт!", isSentByUser: false),
        .init(id: UUID(), text: "Привіт! Як справи?", isSentByUser: true)
    ]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                MessageList(
                    messages: $messages,
                    onReply: { replyingTo = $0 },
                    onForward: { forward($0) },
                    onCopy: { UIPasteboard.general.string = $0.text },
                    onDelete: { delete($0) },
                    onLongPressWithFrame: { msg, frame in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            menuTarget = (msg, frame)
                        }
                    },
                    spaceName: scrollSpace
                )

                Divider()

                // (опційно) прев’ю відповіді
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
            }

            if let t = menuTarget {
                GeometryReader { g in
                    let bubble = t.frame
                    let menuSize = CGSize(width: 280, height: 56)
                    let margin: CGFloat = 10

                    // вибираємо: зверху чи знизу від бульбашки
                    let placeAbove = bubble.maxY + margin + menuSize.height > g.size.height
                    let centerY = placeAbove
                        ? (bubble.minY - margin - menuSize.height / 2)
                        : (bubble.maxY + margin + menuSize.height / 2)

                    let inset: CGFloat = 12
                    let minX = inset + menuSize.width / 2
                    let maxX = g.size.width - inset - menuSize.width / 2
                    let centerX = min(max(bubble.midX, minX), maxX)

                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.spring()) { menuTarget = nil } }

                    MessageActionMenu(
                        onReply:  { replyingTo = t.message; menuTarget = nil },
                        onForward:{ forward(t.message);     menuTarget = nil },
                        onCopy:   { UIPasteboard.general.string = t.message.text; menuTarget = nil },
                        onDelete: { delete(t.message);      menuTarget = nil },
                        onDismiss:{ withAnimation(.spring()) { menuTarget = nil } }
                    )
                    .frame(width: menuSize.width, height: menuSize.height)
                    .position(x: centerX, y: centerY)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                ChatTitleButton(
                    title: chatName,
                    subtitle: "last seen today at 15:34",
                    onTap: { showChatInfo = true }
                )
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                AvatarButton(size: 36) { showChatInfo = true }
            }
        }
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
