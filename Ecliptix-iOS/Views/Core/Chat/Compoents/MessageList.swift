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

    var bottomAnchorId: String = "chat-bottom"
    var onBottomVisibilityChange: (Bool) -> Void = { _ in }

    var grouping: Grouping = .default()

    var body: some View {
        GeometryReader { viewport in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(daySections(from: messages), id: \.date) { section in
                            DateSeparator(date: section.date)

                            ForEach(section.items, id: \.message.id) { item in
                                let idx = item.index
                                let msg = item.message

                                HStack {
                                    if msg.isSentByUser { Spacer() }

                                    MessageBubble(
                                        message: msg,
                                        spaceName: spaceName,
                                        isLastInGroup: grouping.isLastInGroup(idx, messages),
                                        onLongPressWithFrame: { m, frame in
                                            onLongPressWithFrame(m, grouping.isLastInGroup(idx, messages), frame)
                                        }
                                    )

                                    if !msg.isSentByUser { Spacer() }
                                }
                                .id(msg.id)
                                .padding(.top, grouping.spacingAbove(idx, messages))
                            }
                        }

                        Color.clear
                            .frame(height: 1)
                            .id(bottomAnchorId)
                            .onAppear { onBottomVisibilityChange(true) }
                            .onDisappear { onBottomVisibilityChange(false) }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .frame(minHeight: viewport.size.height, alignment: .bottom)
                }
                .onAppear { scrollToBottom(proxy) }
                .onChange(of: messages.count) { scrollToBottom(proxy) }
            }
        }
        .coordinateSpace(name: spaceName)
    }

    private func daySections(from messages: [ChatMessage])
    -> [(date: Date, items: [(index: Int, message: ChatMessage)])] {
        let cal = Calendar.current
        let enumerated = Array(messages.enumerated())

        var buckets: [Date: [(Int, ChatMessage)]] = [:]
        buckets.reserveCapacity(8)

        for (i, msg) in enumerated {
            let day = cal.startOfDay(for: msg.createdAt)
            buckets[day, default: []].append((i, msg))
        }

        let dates = buckets.keys.sorted()
        return dates.map { day in
            let items = (buckets[day] ?? []).sorted { $0.0 < $1.0 }
            return (date: day, items: items.map { (index: $0.0, message: $0.1) })
        }
    }

    struct Grouping {
        let isSameGroup: (_ a: ChatMessage, _ b: ChatMessage) -> Bool
        let isLastInGroup: (_ i: Int, _ messages: [ChatMessage]) -> Bool
        let spacingAbove: (_ i: Int, _ messages: [ChatMessage]) -> CGFloat

        static func `default`(groupGap: TimeInterval = 5 * 60, calendar: Calendar = .current) -> Grouping {
            func same(_ a: ChatMessage, _ b: ChatMessage) -> Bool {
                guard a.isSentByUser == b.isSentByUser else { return false }
                guard calendar.isDate(a.createdAt, inSameDayAs: b.createdAt) else { return false }
                let gap = b.createdAt.timeIntervalSince(a.createdAt)
                return gap <= groupGap
            }
            return Grouping(
                isSameGroup: same,
                isLastInGroup: { i, msgs in
                    guard i + 1 < msgs.count else { return true }
                    return !same(msgs[i], msgs[i + 1])
                },
                spacingAbove: { i, msgs in
                    guard i > 0 else { return 0 }
                    return same(msgs[i - 1], msgs[i]) ? 2 : 8
                }
            )
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(bottomAnchorId, anchor: .bottom)
            }
        }
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
