//
//  MessageList.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct HeightReporter: View {
    var body: some View {
        GeometryReader { g in
            Color.clear.preference(key: ContentHeightKey.self, value: g.size.height)
        }
    }
}

struct MessageList: View {
    @Binding var messages: [ChatMessage]
    var onLongPressWithFrame: (ChatMessage, Bool, CGRect) -> Void = { _,_,_ in }
    var spaceName: String = "chatScroll"

    
    private let groupGap: TimeInterval = 5 * 60
    private let calendar = Calendar.current
    
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        GeometryReader { viewport in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(messages.enumerated()), id: \.element.id) { idx, msg in
                            HStack {
                                if msg.isSentByUser { Spacer() }

                                MessageBubble(
                                    message: msg,
                                    onReply: { _ in },
                                    onForward: { _ in },
                                    onCopy: { _ in },
                                    onDelete: { _ in },
                                    spaceName: spaceName,
                                    isLastInGroup: isLastInGroup(idx, in: messages),
                                    onLongPressWithFrame: { m, frame in
                                        onLongPressWithFrame(m, isLastInGroup(idx, in: messages), frame)      
                                    }
                                )

                                if !msg.isSentByUser { Spacer() }
                            }
                            .id(msg.id)
                            .padding(.top, spacingAbove(idx, in: messages))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)            // your normal bottom padding
                    .background(HeightReporter()) // measure total content height
                    .padding(.top, topPad(viewport: viewport.size.height))
                }
                .onPreferenceChange(ContentHeightKey.self) { contentHeight = $0 }
                .onAppear { scrollToBottom(proxy) }
                .onChange(of: messages.count) { _ in scrollToBottom(proxy) }
            }
        }
        .coordinateSpace(name: spaceName)
    }

    private func topPad(viewport: CGFloat) -> CGFloat {
        // extra space so content touches the bottom when short
        let extra = viewport - contentHeight
        return max(0, extra)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let last = messages.last else { return }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
    
    private func isSameGroup(_ a: ChatMessage, _ b: ChatMessage) -> Bool {
        guard a.isSentByUser == b.isSentByUser else { return false }
        guard calendar.isDate(a.createdAt, inSameDayAs: b.createdAt) else { return false }
        let gap = b.createdAt.timeIntervalSince(a.createdAt)
        return gap <= groupGap
    }
    
    private func isLastInGroup(_ i: Int, in messages: [ChatMessage]) -> Bool {
        guard i + 1 < messages.count else { return true }
        return !isSameGroup(messages[i], messages[i + 1])
    }

    private func spacingAbove(_ i: Int, in messages: [ChatMessage]) -> CGFloat {
        guard i > 0 else { return 0 }
        return isSameGroup(messages[i - 1], messages[i]) ? 2 : 8
    }
}

#Preview {
    @Previewable @State var messages: [ChatMessage] = {
        let now = Date()
        return [
            .init(text: "Привіт!", isSentByUser: false, createdAt: now.addingTimeInterval(-60*30)),
            .init(text: "Як справи?", isSentByUser: false, createdAt: now.addingTimeInterval(-60*29)),

            .init(text: "Все добре! А ти?", isSentByUser: true, createdAt: now.addingTimeInterval(-60*27)),
            .init(text: "Чим займаєшся?", isSentByUser: true, createdAt: now.addingTimeInterval(-60*26)),

            .init(text: "Та нормально.", isSentByUser: false, createdAt: now.addingTimeInterval(-60*16)),

            .init(text: "Чудово 👍", isSentByUser: true, createdAt: now.addingTimeInterval(-60*15)),
            .init(text: "Йду гуляти.", isSentByUser: true, createdAt: now.addingTimeInterval(-60*14)),

            .init(text: "Добре, гарної прогулянки!", isSentByUser: false, createdAt: now),
            
            .init(text: "Чудово 👍", isSentByUser: true, createdAt: now.addingTimeInterval(-60*15)),
            .init(text: "Йду гуляти.", isSentByUser: true, createdAt: now.addingTimeInterval(-60*14)),
            
            .init(text: "Чудово 👍", isSentByUser: true, createdAt: now.addingTimeInterval(-60*7)),
            .init(text: "Йду гуляти.", isSentByUser: true, createdAt: now.addingTimeInterval(-60*6)),
        ]
    }()

    MessageList(messages: $messages)
}
