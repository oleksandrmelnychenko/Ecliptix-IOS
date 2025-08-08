//
//  MessageList.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct MessageList: View {
    @Binding var messages: [ChatMessage]
    var onReply: (ChatMessage) -> Void = { _ in }
    var onForward: (ChatMessage) -> Void = { _ in }
    var onCopy: (ChatMessage) -> Void = { _ in }
    var onDelete: (ChatMessage) -> Void = { _ in }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { msg in
                        HStack {
                            if msg.isSentByUser { Spacer() }

                            TextMessage(message: msg)
                                .contentShape(RoundedRectangle(cornerRadius: 12))
                                .contextMenu {
                                    Button { onReply(msg) }   label: { Label("Reply",   systemImage: "arrowshape.turn.up.left") }
                                    Button { onForward(msg) } label: { Label("Forward", systemImage: "arrowshape.turn.up.right") }
                                    Button { onCopy(msg) }    label: { Label("Copy",    systemImage: "doc.on.doc") }
                                    Button(role: .destructive) { onDelete(msg) } label: { Label("Delete",  systemImage: "trash") }
                                }
                                .padding(.horizontal, 4)

                            if !msg.isSentByUser { Spacer() }
                        }
                        .id(msg.id)
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) {
                if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
    }
}


