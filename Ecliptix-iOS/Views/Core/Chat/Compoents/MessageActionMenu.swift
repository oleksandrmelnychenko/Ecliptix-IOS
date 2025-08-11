//
//  MessageActionMenu.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 11.08.2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct MessageActionMenu: View {
    var onReply: () -> Void
    var onForward: () -> Void
    var onCopy: () -> Void
    var onDelete: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                HStack(spacing: 18) {
                    item("arrowshape.turn.up.left", "Reply", action: onReply)
                    item("arrowshape.turn.up.right", "Forward", action: onForward)
                    item("doc.on.doc", "Copy", action: onCopy)
                    item("trash", "Delete", tint: .red, action: onDelete)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
                Spacer()
            }
            .padding(.bottom, 24)
        }
        .onTapGesture { onDismiss() }
        .accessibilityElement(children: .contain)
    }

    private func item(_ sf: String, _ title: String, tint: Color = .primary, action: @escaping () -> Void) -> some View {
        Button(action: { action(); onDismiss() }) {
            VStack(spacing: 4) {
                Image(systemName: sf)
                Text(title).font(.caption2)
            }
            .foregroundColor(tint)
            .frame(width: 52)
        }
        .buttonStyle(.plain)
    }
}
