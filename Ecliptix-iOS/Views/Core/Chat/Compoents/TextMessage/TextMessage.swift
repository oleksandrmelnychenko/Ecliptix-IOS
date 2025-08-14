//
//  TextMessage.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct TextMessage: View {
    @Binding var message: ChatMessage
    let isLastInGroup: Bool
    let r: CGFloat = 16

    private var fill: Color { message.isSentByUser ? .blue : .white }
    private var textColor: Color { message.isSentByUser ? .white : .primary }

    

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            Text(message.text)
                .foregroundColor(textColor)
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: TextWidthKey.self, value: geo.size.width)
                    }
                )

            TimestampBadge(date: message.updatedAt ?? message.createdAt, status: message.status, tint: textColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
        .background(
            ChatBubbleShape(
                isFromCurrentUser: message.isSentByUser,
                showTail: isLastInGroup,
                cornerRadius: r)
                .fill(fill)
        )
        .frame(maxWidth: UIScreen.main.bounds.width * 0.8,
               alignment: message.isSentByUser ? .trailing : .leading)
        .onPreferenceChange(TextWidthKey.self) { textWidth in
            checkIfNeedsExtraPadding(textWidth: textWidth)
        }
        .onPreferenceChange(TimeWidthKey.self) { timeWidth in
            checkIfNeedsExtraPadding(timeWidth: timeWidth)
        }
    }

    @State private var needsExtraPadding = false
    @State private var measuredTextWidth: CGFloat = 0
    @State private var measuredTimeWidth: CGFloat = 0

    private func checkIfNeedsExtraPadding(textWidth: CGFloat? = nil, timeWidth: CGFloat? = nil) {
        if let tw = textWidth { measuredTextWidth = tw }
        if let tw = timeWidth { measuredTimeWidth = tw }

        let maxWidth = UIScreen.main.bounds.width * 0.8 - 24
        needsExtraPadding = (measuredTextWidth + measuredTimeWidth + 4) > maxWidth
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

#Preview("Outcome. Large message") {
    VStack {
        Spacer()
        TextMessage(
            message: .constant(.init(id: UUID(), text: "Hi this is a very long message to see how it behaves behaves behaves behaves behaves behaves behaves behaves behaves", isSentByUser: true)), isLastInGroup: true)
    }
    .padding(.horizontal)
}
