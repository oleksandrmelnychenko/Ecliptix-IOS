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
    
    @State private var menuTarget: (message: ChatMessage, isLastInGroup: Bool, frame: CGRect)?
    private let scrollSpace = "chatScroll"
    
    // Chat state
    @State private var showChatInfo = false
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = [
        // Група 1 (інший користувач, щільно)
        .init(text: "Привіт! 👋",                  isSentByUser: false, createdAt: Date().addingTimeInterval(-60*180)),
        .init(text: "Є хвилинка поговорити?",      isSentByUser: false, createdAt: Date().addingTimeInterval(-60*179)),
        .init(text: "Потрібна порада",             isSentByUser: false, createdAt: Date().addingTimeInterval(-60*177)),

        // Група 2 (я, близько)
        .init(text: "Привіт! Звісно 🙂",           isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*175)),
        .init(text: "Про що саме?",                isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*174)),

        // Група 3 (інший, після 20 хв — нова група)
        .init(text: "Думаю переписати UI чату",    isSentByUser: false, createdAt: Date().addingTimeInterval(-60*154)),

        // Група 4 (я, близько)
        .init(text: "Класна ідея!",                isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*153)),
        .init(text: "Можемо почати з бульбашок",   isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*152)),

        // Група 5 (інший, +2 год — нова група)
        .init(text: "Додав хвостик до бульбашки",  isSentByUser: false, createdAt: Date().addingTimeInterval(-60*120)),
        .init(text: "Поглянь, ок?",                isSentByUser: false, createdAt: Date().addingTimeInterval(-60*119)),

        // Група 6 (я)
        .init(text: "Виглядає добре 👍",           isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*117)),
        .init(text: "Трохи підкручу криву Безьє",  isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*116)),
        .init(text: "І буде супер",                isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*115)),

        // Група 7 (інший, +1 год — нова група)
        .init(text: "Що з відступами між групами?",isSentByUser: false, createdAt: Date().addingTimeInterval(-60*60)),

        // Група 8 (я)
        .init(text: "Зробив 2pt всередині групи",  isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*59)),
        .init(text: "І 8pt між групами",           isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*58)),

        // Група 9 (інший, 13 хв — нова група)
        .init(text: "Супер. А час поруч із текстом?", isSentByUser: false, createdAt: Date().addingTimeInterval(-60*45)),
        .init(text: "Як у Telegram",                isSentByUser: false, createdAt: Date().addingTimeInterval(-60*44)),

        // Група 10 (я)
        .init(text: "Так, міряю ширину",           isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*30)),
        .init(text: "Якщо не вміщується — вниз",   isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*29)),

        // Група 11 (інший)
        .init(text: "Тепер б хотів градієнт фонового екрану", isSentByUser: false, createdAt: Date().addingTimeInterval(-60*15)),

        // Група 12 (я)
        .init(text: "Додав легкий зверху-вниз",    isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*14)),
        .init(text: "Пасує до теми",               isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*10)),
        .init(text: "Ледь помітний",               isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*9)),

        // Група 13 (інший)
        .init(text: "Чудово, дякую!",              isSentByUser: false, createdAt: Date().addingTimeInterval(-60*5)),
        .init(text: "Ще підкоригую колір",         isSentByUser: false, createdAt: Date().addingTimeInterval(-60*4)),

        // Група 14 (я)
        .init(text: "Ок, пінгани якщо що",         isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*3)),
        .init(text: "Готово 👌",                   isSentByUser: true,  createdAt: Date().addingTimeInterval(-60*2)),

        // Група 15 (інший)
        .init(text: "Бачу. Все працює!",           isSentByUser: false, createdAt: Date().addingTimeInterval(-60*1)),

        // Останнє (я)
        .init(text: "🔥 Тоді зливаю в main",        isSentByUser: true,  createdAt: Date())
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
                    onLongPressWithFrame: { msg, isLast, frame in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            menuTarget = (msg, isLast, frame)
                        }
                    },
                    spaceName: scrollSpace
                )
                .padding(.top, 20)

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
        .overlay(
            Group {
                if let t = menuTarget {
                    ZStack {
                        // бекдроп
                        Color.clear
                            .background(.ultraThinMaterial)
                            .overlay(Color.black.opacity(0.08))
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                    menuTarget = nil
                                }
                            }

                        
                        HStack {
                            if (t.message.isSentByUser) {
                                Spacer()
                            }
                            
                            ContextMenuOverlay(
                                textMessage: .constant(
                                    TextMessage(message: t.message, isLastInGroup: t.isLastInGroup)
                                ),
                                onReply:  { msg in replyingTo = msg; menuTarget = nil },
                                onForward:{ msg in forward(msg);    menuTarget = nil },
                                onCopy:   { _   in UIPasteboard.general.string = t.message.text; menuTarget = nil },
                                onDelete: { msg in delete(msg);     menuTarget = nil }
                            )
                            .transition(.scale.combined(with: .opacity))
                            
                            if (!t.message.isSentByUser) {
                                Spacer()
                            }
                        }
                    }
                    .animation(.spring(response: 0.32, dampingFraction: 0.86),
                               value: menuTarget != nil)
                }
            }
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
