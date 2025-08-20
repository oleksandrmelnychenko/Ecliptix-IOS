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
    @Published var isSelecting = false
    @Published var selected: Set<UUID> = []
    @Published var forwardingBatch: [ChatMessage]? = nil
    @Published var overlay: ComposerOverlay? = nil

    // UI sheets / pickers
    @Published var showChatInfo = false
    @Published var showPhotoPicker = false
    @Published var showCamera = false
    @Published var showDocumentPicker = false
    @Published var selectedPhoto: PhotosPickerItem? = nil
    @Published var selectedDocumentURL: URL? = nil

    var selectionCount: Int { selected.count }
    
    // MARK: - Constants
    let scrollSpace = "chatScroll"
    let bottomAnchorId = "chat-bottom"
    let groupGap: TimeInterval = 5 * 60
    private let calendar = Calendar.current

    // MARK: - Init
    init(seed: [ChatMessage] = []) {
        self.messages = seed.isEmpty ? Seed.makeMessages(days: 20) : seed
    }

    // MARK: - Actions
    @MainActor
    func send() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 3.1 Редагування
        if let editing {
            updateMessage(id: editing.id) { m in
                m.text = trimmed
                m.updatedAt = Date()
                m.status = .sent
            }
            messageText = ""
            self.editing = nil
            self.replyingTo = nil
            clearOverlay()
            return
        }

        // 3.2 Нова відправка (з можливим reply)
        var new = ChatMessage(text: trimmed, side: .outgoing, time: "16:00", status: .sending)

        if case let .reply(target) = overlay {
            new.replyTo = makeReplyRef(from: target)
        } else if let target = replyingTo {
            new.replyTo = makeReplyRef(from: target)
        }

        messages.append(new)
        messageText = ""
        clearOverlay()          // обнуляємо overlay/reply

        // емуляція переходу статусу
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            updateMessage(id: new.id) { $0.status = .sent }
        }
    }
    
    private func makeReplyRef(from m: ChatMessage) -> ReplyRef {
        ReplyRef(
            id: m.id,
            author: m.side == .outgoing ? "You" : "Bot",
            preview: m.text
        )
    }

    func onReply(_ msg: ChatMessage) {
        overlay = .reply(msg)
        replyingTo = msg
    }
    
    func forward(_ msg: ChatMessage, to chat: Chat) {
        print("Forward '\(msg.text)' to chat: \(chat.name)")
    }
    
    func startForwarding(_ msg: ChatMessage) {
        forwardingMessage = msg
    }
    
    func edit(_ msg: ChatMessage) {
        overlay = .edit(msg)
        editing = msg
        messageText = msg.text
    }
    
    func copy(_ msg: ChatMessage) {
        UIPasteboard.general.string = msg.text
    }

    func delete(_ msg: ChatMessage) {
        messages.removeAll { $0.id == msg.id }
        if replyingTo?.id == msg.id { replyingTo = nil }
        if editing?.id == msg.id { editing = nil }
    }
    
    func beginSelection(with id: UUID) {
        isSelecting = true
        selected = [id]
    }
    
    func toggleSelection(_ id: UUID) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
        if selected.isEmpty { isSelecting = false }
    }
    
    func clearChat() {
        clearSelection()
        messages.removeAll()
    }
    
    func clearSelection() {
        selected.removeAll()
        isSelecting = false
    }
    
    func deleteSelected() {
        guard !selected.isEmpty else { return }
        messages.removeAll { selected.contains($0.id) }
        clearSelection()
    }

    func forwardSelected() {
        guard !selected.isEmpty else { return }
        forwardingBatch = messages.filter { selected.contains($0.id) }
        isSelecting = false
        selected.removeAll()
    }
    
    func clearOverlay() {
        overlay = nil
    }

    @MainActor
    func setBottomVisible(_ visible: Bool) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            isAtBottom = visible
        }
    }
    
    @MainActor
    private func updateMessage(id: UUID, _ mutate: (inout ChatMessage) -> Void) {
        
    }

    // MARK: - Grouping helpers 
    func isSameGroup(_ a: ChatMessage, _ b: ChatMessage) -> Bool {
        guard a.side == b.side else { return false }
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


enum ComposerOverlay: Identifiable, Equatable {
    case reply(ChatMessage)
    case edit(ChatMessage)

    var id: UUID {
        switch self {
        case .reply(let m): return m.id
        case .edit(let m):  return m.id
        }
    }

    var message: ChatMessage {
        switch self {
        case .reply(let m), .edit(let m): return m
        }
    }
}

private enum Seed {
    static func makeMessages(days: Int = 14) -> [ChatMessage] {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())

        func at(daysAgo: Int, hour: Int, minute: Int) -> Date {
            // базовий день -N від сьогодні 00:00, далі додаємо хвилини
            let day = cal.date(byAdding: .day, value: -daysAgo, to: todayStart)!
            return cal.date(byAdding: .minute, value: hour * 60 + minute, to: day)!
        }

        let otherTexts = [
            "Привіт! 👋", "Є хвилинка поговорити?", "Потрібна порада", "Гоу оновимо UI?",
            "Додав хвостик до бульбашки", "Поглянь, ок?", "Що з відступами між групами?",
            "Супер. А час поруч із текстом?", "Як у Telegram", "Чудово, дякую!", "Ще підкоригую колір"
        ]
        let myTexts = [
            "Привіт! Звісно 🙂", "Про що саме?", "Класна ідея!", "Можемо почати з бульбашок",
            "Виглядає добре 👍", "Трохи підкручу криву Безьє", "І буде супер",
            "Так, міряю ширину", "Якщо не вміщується — вниз", "Додав легкий зверху-вниз",
            "Пасує до теми", "Ледь помітний", "Ок, пінгани якщо що", "Готово 👌",
            "🔥 Тоді зливаю в main"
        ]

        var out: [ChatMessage] = []
        var iOther = 0, iMe = 0

        for d in stride(from: days, through: 0, by: -1) {
            let count = 2 + (d % 4)
            var sentByUser = (d % 2 != 0)

            for i in 0..<count {
                let hour = 9 + ((i * 3 + d) % 11)
                let minute = (i * 13 + d * 7) % 60

                let text: String
                if sentByUser {
                    text = myTexts[iMe % myTexts.count]; iMe += 1
                } else {
                    text = otherTexts[iOther % otherTexts.count]; iOther += 1
                }

                out.append(
                    ChatMessage(
                        text: text,
                        side: sentByUser ? .outgoing : .incoming,
                        time: "16:00",
                        createdAt: at(daysAgo: d, hour: hour, minute: minute)
                    )
                )

                sentByUser.toggle()
            }
        }

        return out.sorted { $0.createdAt < $1.createdAt }
    }
}
