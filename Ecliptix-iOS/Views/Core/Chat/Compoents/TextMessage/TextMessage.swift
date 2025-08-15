//
//  TextMessage.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI

struct TextMessage: View {
    @Binding var message: ChatMessage
    let isLastInGroup: Bool
    var onTapReply: ((UUID) -> Void)? = nil
    let r: CGFloat = 16

    private var fill: Color { message.isSentByUser ? .blue : .white }
    private var textColor: Color { message.isSentByUser ? .white : .primary }

    @State private var textW: CGFloat = 0
    @State private var timeW: CGFloat = 0

    private let bubbleHPad: CGFloat = 12
    private let spacingTextTime: CGFloat = 6
    private var bubbleMaxW: CGFloat { UIScreen.main.bounds.width * 0.8 }
    private var contentMaxW: CGFloat { bubbleMaxW - bubbleHPad * 2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let reply = message.replyTo {
                InlineReplySnippet(
                    isOutgoing: message.isSentByUser,
                    reply: reply,
                    onTap: { onTapReply?(reply.id) }
                )
//                .frame(maxWidth: contentMaxW, alignment: .leading)
            }

            HStack(alignment: .bottom, spacing: spacingTextTime) {
                Text(verbatim: message.text)
                    .foregroundColor(textColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        GeometryReader { g in
                            Color.clear.preference(key: TextWidthKey.self, value: g.size.width)
                        }
                    )

                TimestampBadge(
                    date: message.updatedAt ?? message.createdAt,
                    status: message.status,
                    tint: textColor
                )
                .fixedSize()
                .background(
                    GeometryReader { g in
                        Color.clear.preference(key: TimeWidthKey.self, value: g.size.width)
                    }
                )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, bubbleHPad)
        .padding(.bottom, 4)
        .background(
            ChatBubbleShape(
                isFromCurrentUser: message.isSentByUser,
                showTail: isLastInGroup,
                cornerRadius: r
            ).fill(fill)
        )
        .frame(maxWidth: bubbleMaxW,
               alignment: message.isSentByUser ? .trailing : .leading)
        .onPreferenceChange(TextWidthKey.self) { textW = $0 }
        .onPreferenceChange(TimeWidthKey.self) { timeW = $0 }
    }
}


private struct TextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
private struct TimeWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}


#Preview("Income") {
    TextMessage(
        message: .constant(.init(id: UUID(), text: "Hello, world!", isSentByUser: false)), isLastInGroup: true)
}

#Preview("Outcome") {
    TextMessage(
        message: .constant(.init(id: UUID(), text: "Hi", isSentByUser: true)), isLastInGroup: true)
    .padding()
}

#Preview("Outcome with reply") {
    TextMessage(
        message: .constant(.init(id: UUID(), text: "Hi", isSentByUser: true, replyTo: .init(id: UUID(), author: "Roman", text: "AAA"))), isLastInGroup: true)
    .padding()
}

#Preview("Outcome. Large message") {
    VStack {
        Spacer()
        TextMessage(
            message: .constant(.init(id: UUID(), text: "Hi this is a very long message to see how it behaves behaves behaves behaves behaves behaves behaves behaves behaves", isSentByUser: true)), isLastInGroup: true)
    }
    .padding(.horizontal)
}
