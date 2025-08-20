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

    private var fill: Color { message.side == .outgoing ? .blue : .white }
    private var textColor: Color { message.side == .outgoing ? .white : .primary }

    @State private var replWidth: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var lastTextLineWidth: CGFloat = 0
    @State private var timeWidth: CGFloat = 0
    @State private var paddingWidth: CGFloat = 0
    
    private static let bubbleRadius: CGFloat = 16
    private static let bubbleHPad: CGFloat = 14
    private static let bubbleVPad: CGFloat = 8
    private static let spaceBetweenTextAndTime: CGFloat = 6
    private static let spaceBeloweTextAndTime: CGFloat = 4
    private static let spaceBetweenHeaderAndHeader: CGFloat = 6
    private var bubbleMaxW: CGFloat { UIScreen.main.bounds.width * 0.8 }

    var body: some View {
        InlineMessageLayout(
            spacing: Self.spaceBetweenTextAndTime,
            belowSpacing: Self.spaceBeloweTextAndTime,
            headerSpacing: Self.spaceBetweenHeaderAndHeader,
            lastTextLineW: lastTextLineWidth,
            headerW: replWidth
        ) {
                if let r = message.replyTo {
                    HStack {
                        ReplySnippetView(
                            isOutgoing: message.side == .outgoing,
                            author: r.author,
                            preview: r.preview
                        )
                        .lineLimit(1)
                        .background(
                            GeometryReader { g in
                                Color.clear.preference(key: ReplyWidthsKey.self, value: g.size.width)
                            }
                        )
                        .onPreferenceChange(ReplyWidthsKey.self) { newWidth in
                            replWidth = newWidth
                        }
                        
                    }
                    .padding(.vertical, 8)
                    .padding(.trailing, paddingWidth)
                    .background((message.side == .outgoing ? Color.white.opacity(0.12) : Color.blue.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous)))
                    .contentShape(Rectangle())
                }
                
            Text(message.text)
                .font(.body)
                .foregroundStyle(textColor)
                .background(
                    GeometryReader { g in
                        Color.clear.preference(key: TextWidthsKey.self, value: g.size.width)
                    }
                )
                .background(
                    LineWidthsReader(
                        text: message.text,
                        font: UIFont.preferredFont(forTextStyle: .body),
                        containerWidth: bubbleMaxW
                    ) { widths in
                        lastTextLineWidth = widths.last ?? 0
                    }
                )
                .onPreferenceChange(TextWidthsKey.self) { newWidth in
                    DispatchQueue.main.async {
                        textWidth = newWidth
                        paddingWidth = textWidth + 6 + timeWidth > bubbleMaxW
                            ? max(0, textWidth - replWidth)
                            : max(0, textWidth + 6 + timeWidth - replWidth)
                    }
                }
            
            Text(message.time)
                .font(.caption2)
                .foregroundStyle(textColor.opacity(0.7))
                .background(
                    GeometryReader { g in
                        Color.clear.preference(key: TimeWidthsKey.self, value: g.size.width)
                    }
                )
                .onPreferenceChange(TimeWidthsKey.self) { newWidth in
                    timeWidth = newWidth
                }
            
            }
        .padding(.horizontal, Self.bubbleHPad)
        .padding(.vertical, Self.bubbleVPad)
            .background(
                ChatBubbleShape(
                    isFromCurrentUser: message.side == .outgoing,
                    showTail: isLastInGroup,
                    cornerRadius: Self.bubbleRadius
                )
                .fill(fill)
            )
            .frame(maxWidth: bubbleMaxW + Self.bubbleHPad * 2, alignment: message.side == .outgoing ? .trailing : .leading)
        }
}

private struct ReplyWidthsKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct TimeWidthsKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct TextWidthsKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}


#Preview("Income") {
    TextMessage(
        message: .constant(.init(id: UUID(), text: "Hello, world!", side: .incoming, time: "16:00")), isLastInGroup: true)
}

#Preview("Outcome") {
    TextMessage(
        message: .constant(.init(id: UUID(), text: "Hi", side: .outgoing, time: "16:00")), isLastInGroup: true)
    .padding()
}

#Preview("Outcome with reply") {
    TextMessage(
        message: .constant(.init(id: UUID(), text: "Hi", side: .outgoing, time: "16:00", replyTo: .init(id: UUID(), author: "Roman", preview: "AAA"))), isLastInGroup: true)
    .padding()
}

#Preview("Outcome. Large message") {
    VStack {
        Spacer()
        TextMessage(
            message: .constant(.init(id: UUID(), text: "Hi this is a very long message to see how it behaves behaves behaves behaves behaves behaves behaves behaves behaves", side: .outgoing, time: "16:00")), isLastInGroup: true)
    }
    .padding(.horizontal)
}
