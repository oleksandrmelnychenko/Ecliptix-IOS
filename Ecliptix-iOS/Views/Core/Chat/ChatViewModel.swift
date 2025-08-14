//
//  ChatViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.08.2025.
//

import SwiftUI
import PhotosUI

final class ChatViewModel: ObservableObject {
    // MARK: - Published state
    @Published var messages: [ChatMessage]
    @Published var messageText: String = ""
    @Published var replyingTo: ChatMessage? = nil
    @Published var editing: ChatMessage? = nil
    @Published var forwardingMessage: ChatMessage? = nil
    @Published var isAtBottom: Bool = true

    // UI sheets / pickers
    @Published var showChatInfo = false
    @Published var showPhotoPicker = false
    @Published var showCamera = false
    @Published var showDocumentPicker = false
    @Published var selectedPhoto: PhotosPickerItem? = nil
    @Published var selectedDocumentURL: URL? = nil

    // MARK: - Constants
    let scrollSpace = "chatScroll"
    let bottomAnchorId = "chat-bottom"
    let groupGap: TimeInterval = 5 * 60
    private let calendar = Calendar.current

    // MARK: - Init
    init(seed: [ChatMessage] = []) {
        self.messages = [
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
    }

    // MARK: - Actions
    func send() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let new = ChatMessage(text: trimmed, isSentByUser: true, status: .sending)
        messages.append(new)
        messageText = ""
        replyingTo = nil
        editing = nil

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            if let idx = messages.firstIndex(where: { $0.id == new.id }) {
                messages[idx].status = .sent
            }
        }
    }

    func forward(_ msg: ChatMessage, to chat: Chat) {
        print("Forward '\(msg.text)' to chat: \(chat.name)")
    }
    
    func startForwarding(_ msg: ChatMessage) {
        forwardingMessage = msg
    }
    
    func copy(_ msg: ChatMessage) {
        UIPasteboard.general.string = msg.text
    }

    func delete(_ msg: ChatMessage) {
        messages.removeAll { $0.id == msg.id }
    }

    @MainActor
    func setBottomVisible(_ visible: Bool) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            isAtBottom = visible
        }
    }

    // MARK: - Grouping helpers 
    func isSameGroup(_ a: ChatMessage, _ b: ChatMessage) -> Bool {
        guard a.isSentByUser == b.isSentByUser else { return false }
        guard calendar.isDate(a.createdAt, inSameDayAs: b.createdAt) else { return false }
        let gap = b.createdAt.timeIntervalSince(a.createdAt)
        return gap <= groupGap
    }

    func isLastInGroup(index i: Int) -> Bool {
        guard i + 1 < messages.count else { return true }
        return !isSameGroup(messages[i], messages[i + 1])
    }

    func spacingAbove(index i: Int) -> CGFloat {
        guard i > 0 else { return 0 }
        return isSameGroup(messages[i - 1], messages[i]) ? 2 : 8
    }
}
