//
//  MessageBubble.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//

import SwiftUI

// Bound preference FrameInSpaceKey tried to update multiple times per frame.
private struct FrameInSpaceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private func snap(_ v: CGFloat) -> CGFloat {
    let s = UIScreen.main.scale
    return (v * s).rounded() / s
}

private func snap(_ r: CGRect) -> CGRect {
    CGRect(x: snap(r.origin.x), y: snap(r.origin.y),
           width: snap(r.size.width), height: snap(r.size.height))
}

private func nearlyEqual(_ a: CGRect, _ b: CGRect, eps: CGFloat = 0.5) -> Bool {
    abs(a.origin.x - b.origin.x) < eps &&
    abs(a.origin.y - b.origin.y) < eps &&
    abs(a.size.width - b.size.width) < eps &&
    abs(a.size.height - b.size.height) < eps
}

struct MessageBubble: View {
    @Binding var message: ChatMessage
    var spaceName: String = "chatScroll"
    var isLastInGroup: Bool = true
    var onLongPressWithFrame: (ChatMessage, CGRect) -> Void = { _, _ in }

    @State private var frameInScroll: CGRect = .zero

    var body: some View {
        TextMessage(message: $message, isLastInGroup: isLastInGroup)
            .overlay(alignment: .topLeading) {
                GeometryReader { geo in
                    let rect = geo.frame(in: .named(spaceName))
                    Color.clear
                        .preference(key: FrameInSpaceKey.self, value: rect)
                }
            }
            .onPreferenceChange(FrameInSpaceKey.self) { newRect in
                let snapped = snap(newRect)
                guard !nearlyEqual(snapped, frameInScroll) else { return }
                DispatchQueue.main.async {
                    frameInScroll = snapped
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onLongPressGesture(minimumDuration: 0.3) {
                onLongPressWithFrame(message, frameInScroll)
            }
    }
}

#Preview("Incoming") {
    MessageBubble(message: .constant(ChatMessage(id: UUID(), text: "Demo text", side: .incoming, time: "16:00")))
}

#Preview("Outgoing") {
    MessageBubble(message: .constant(ChatMessage(id: UUID(), text: "Demo text", side: .outgoing, time: "16:00")))
}

#Preview("Both") {
    VStack(spacing: 12) {
        HStack {
            MessageBubble(message: .constant(ChatMessage(id: UUID(), text: "Demo text", side: .incoming, time: "16:00")))
            Spacer()
        }
        HStack {
            Spacer()
            MessageBubble(message: .constant(ChatMessage(id: UUID(), text: "Demo text", side: .outgoing, time: "16:00")))
        }
    }
}

