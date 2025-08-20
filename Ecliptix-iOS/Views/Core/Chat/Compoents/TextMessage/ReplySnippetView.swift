//
//  InlineReplySnippet.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 15.08.2025.
//

import SwiftUI

struct InlineReplySnippet: View {
    let isOutgoing: Bool
    let reply: ReplyRef
    var onTap: (() -> Void)?

    private var bg: Color   { isOutgoing ? .white.opacity(0.12) : .gray.opacity(0.12) }
    private var title: Color{ isOutgoing ? .white.opacity(0.85)  : .secondary }
    private var text: Color { isOutgoing ? .white               : .primary }
    private var bar: Color  { isOutgoing ? .white.opacity(0.9)  : .blue }

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(bar)
                .frame(width: 3, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(reply.author)
                    .font(.caption)
                    .foregroundColor(title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(verbatim: reply.text)
                    .font(.subheadline)
                    .foregroundColor(text)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onTapGesture { onTap?() }
    }
}

struct AuthorWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

#Preview {
    InlineReplySnippet(isOutgoing: false, reply: .init(id: UUID(), author: "Roman", text: "Demo"))
}
