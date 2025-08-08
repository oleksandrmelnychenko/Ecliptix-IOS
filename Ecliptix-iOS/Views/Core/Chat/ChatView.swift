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
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showDocumentPicker = false
    @State private var selectedDocumentURL: URL?

    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = [
        .init(id: UUID(), text: "Привіт!", isSentByUser: false),
        .init(id: UUID(), text: "Привіт! Як справи?", isSentByUser: true)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isSentByUser {
                                    Spacer()
                                }

                                TextMessage(message: message)

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
                Menu {
                    Button("Choose Photo", action: selectPhoto)
                    Button("Take Photo", action: takePhoto)
                    Button("Attach Document", action: attachFile)
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                        .padding(8)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Add attachment")
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
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(chatName)
                        .font(.headline)
                        .bold()

                    Text("last seen today at 15:34")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            }
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
    
    @State private var showPhotoPicker = false

    private func selectPhoto() {
        showPhotoPicker = true
    }

    private func takePhoto() {
        showCamera = true
    }

    private func attachFile() {
        showDocumentPicker = true
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



struct TextMessage: View {
    let message: ChatMessage
    
    var body: some View {
        Text(message.text)
            .padding(10)
            .background(message.isSentByUser ? Color.blue : Color.gray.opacity(0.3))
            .foregroundColor(message.isSentByUser ? .white : .black)
            .cornerRadius(12)
            .frame(maxWidth: 250, alignment: message.isSentByUser ? .trailing : .leading)
    }
}

#Preview {
    ChatView(chatName: "Roman")
}
