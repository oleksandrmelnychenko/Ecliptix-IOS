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

    @State private var replyingTo: ChatMessage?
    
    // Chat state
    @State private var showChatInfo = false
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = [
        .init(id: UUID(), text: "Привіт!", isSentByUser: false),
        .init(id: UUID(), text: "Привіт! Як справи?", isSentByUser: true)
    ]

    var body: some View {
        VStack(spacing: 0) {
            MessageList(messages: $messages,
                onReply: { replyingTo = $0 },
                onForward: { forward($0) },
                onCopy: { UIPasteboard.general.string = $0.text },
                onDelete: { delete($0) }
            )

            Divider()

            InputBar(
                text: $messageText,
                onSend: sendMessage,
                onChoosePhoto: { showPhotoPicker = true },
                onTakePhoto: { showCamera = true },
                onAttachFile: { showDocumentPicker = true }
            )
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
        .sheet(isPresented: $showChatInfo) {
            ChatInfoView(chatName: chatName)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto)
        .sheet(isPresented: $showCamera) {
            Text("Camera not implemented")
        }
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
