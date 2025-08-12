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
    var onLongPressWithFrame: (ChatMessage, CGRect) -> Void = { _, _ in }
    var spaceName: String = "chatScroll"

    @State private var contentHeight: CGFloat = 0

    var body: some View {
        GeometryReader { viewport in              // get visible height
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
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
                                    onLongPressWithFrame: onLongPressWithFrame
                                )

                                if !msg.isSentByUser { Spacer() }
                            }
                            .id(msg.id)
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
        // Keep newest visible when content grows
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
    
    private func isLastInGroup(_ i: Int, in messages: [ChatMessage]) -> Bool {
        // останній у всьому списку — завжди останній у групі
        guard i + 1 < messages.count else { return true }

        let cur  = messages[i]
        let next = messages[i + 1]

        // інший відправник -> нова група
        if cur.isSentByUser != next.isSentByUser { return true }

        return false
    }
}

//@Binding var messages: [ChatMessage]
//var onReply: (ChatMessage) -> Void = { _ in }
//var onForward: (ChatMessage) -> Void = { _ in }
//var onCopy: (ChatMessage) -> Void = { _ in }
//var onDelete: (ChatMessage) -> Void = { _ in }
//var onLongPressWithFrame: (ChatMessage, CGRect) -> Void = { _, _ in }
//var spaceName: String = "chatScroll"

//MessageBubble(
//    message: msg,
//    onReply: onReply,
//    onForward: onForward,
//    onCopy: onCopy,
//    onDelete: onDelete,
//    spaceName: spaceName,
//    onLongPressWithFrame: onLongPressWithFrame
//)

#Preview {
    @Previewable @State var messages: [ChatMessage] = [
        .init(id: UUID(), text: "Привіт!", isSentByUser: false),
        .init(id: UUID(), text: "Привіт! Як справи?", isSentByUser: true),
        .init(id: UUID(), text: "Привіт!", isSentByUser: false),
        .init(id: UUID(), text: "Привіт! Як справи?", isSentByUser: true),
        .init(id: UUID(), text: "Привіт!", isSentByUser: false),
        .init(id: UUID(), text: "Привіт! Як справи?", isSentByUser: true),
        .init(id: UUID(), text: "Привіт!", isSentByUser: false),
        .init(id: UUID(), text: "Привіт! Як справи?", isSentByUser: true),
        .init(id: UUID(), text: "Привіт!", isSentByUser: false),
        .init(id: UUID(), text: "Привіт! Як справи?", isSentByUser: true),
        .init(id: UUID(), text: "Привіт!", isSentByUser: false),
        .init(id: UUID(), text: "Привіт! Як справи?", isSentByUser: true)
    ]
    
    MessageList(
        messages: $messages
//        onReply: { _ in },
//        onForward: { _ in },
//        onCopy: { _ in },
//        onDelete: { _ in }
    )
}
