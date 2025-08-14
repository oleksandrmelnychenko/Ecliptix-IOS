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
    var status: Text? = nil
    
    // actions
    var onReply: () -> Void
    var onForward: () -> Void
    var onCopy: () -> Void
    var onDelete: () -> Void
    var onDismiss: () -> Void
    var onEdit: (() -> Void)? = nil
    var onSelect: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            
            if let status {
                HStack(alignment: .center, spacing: 4) {
                    Image(systemName: "checkmark")
                    status
                    Spacer()
                }
                .padding(.horizontal, 18)
                .font(.caption2)
                .foregroundColor(.primary)

                Divider()
                    .frame(width: 210, height: 6)
                    .overlay(.lightButtonBackground)
            }
            
            // Main actions
            ContextMenuItem(sf: "arrowshape.turn.up.left", title: "Reply", action: onReply)
            ContextMenuItem(sf: "arrowshape.turn.up.right", title: "Forward", action: onForward)
            ContextMenuItem(sf: "doc.on.doc", title: "Copy", action: onCopy)
            
            if let onEdit {
                ContextMenuItem(sf: "pencil", title: "Edit", action: onEdit)
            }
            
            ContextMenuItem(sf: "trash", title: "Delete", showDivider: false, tint: .red, action: onDelete)
            
            Divider()
                .frame(width: 210, height: 6)
                .overlay(.lightButtonBackground)
            
            ContextMenuItem(sf: "checkmark.circle", title: "Select", showDivider: false, action: onSelect)
        }
        .padding(.vertical, 10)
        .frame(width: 210)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerSize: .init(width: 14, height: 14)))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 6)
    }
}

#Preview {
    MessageActionMenu(
        onReply: {},
        onForward: {},
        onCopy: {},
        onDelete: {},
        onDismiss: {},
        onSelect: {}
    )
}
