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
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 4) {
                Image(systemName: "checkmark")
                Text("read today at 18:00")
                
                Spacer()
            }
            .padding(.horizontal, 18)
            .font(.caption2)
            .foregroundColor(.primary)
            
            Divider()
                .frame(width: 210, height: 6)
                .overlay(.lightButtonBackground)
            
            item("arrowshape.turn.up.left", "Reply", action: onReply)
            item("arrowshape.turn.up.right", "Forward", action: onForward)
            item("doc.on.doc", "Copy", action: onCopy)
            item("trash", "Delete", showDivider: false, tint: .red, action: onDelete)
            
            Divider()
                .frame(width: 210, height: 6)
                .overlay(.lightButtonBackground)
            
            item("checkmark.circle", "Select", showDivider: false, action: onReply)
        }
        .padding(.vertical, 10)
        .frame(width: 210)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerSize: .init(width: 14, height: 14)))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 6)
    }

    private func item(
        _ sf: String,
        _ title: String,
        showDivider: Bool = true,
        tint: Color = .primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: { action(); onDismiss() }) {
            VStack {
                HStack(spacing: 4) {
                    Text(title)
                    
                    Spacer()
                    
                    Image(systemName: sf)
                }
                .foregroundColor(tint)
                .padding(.horizontal, 18)
                
                if showDivider {
                    Divider()
                }
            }
            
        }
        
        .buttonStyle(.plain)
    }
}

#Preview {
    MessageActionMenu(
        onReply: {},
        onForward: {},
        onCopy: {},
        onDelete: {},
        onDismiss: {}
    )
}
