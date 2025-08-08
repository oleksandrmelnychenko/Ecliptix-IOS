//
//  ChatsTopMenu.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI

struct ChatsTopMenu: View {
    @Binding var mode: ChatsMode
    var clearSelection: () -> Void

    var body: some View {
        Group {
            if mode == .selecting {
                Button("Done") {
                    clearSelection()
                    mode = .browsing
                }
            } else {
                Menu {
                    Button {
                        // Read all
                    } label: {
                        Label("Read all", systemImage: "checkmark.bubble")
                    }

                    Button {
                        mode = .selecting
                    } label: {
                        Label("Select chats", systemImage: "checkmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .padding(12)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
        }
    }
}

// MARK: - Previews

private struct ChatsTopMenuPreview_Browsing: View {
    @State private var mode: ChatsMode = .browsing
    var body: some View {
        ChatsTopMenu(mode: $mode, clearSelection: {})
            .padding()
            .background(Color(.systemBackground))
    }
}

#Preview("Browsing") {
    ChatsTopMenuPreview_Browsing()
}

private struct ChatsTopMenuPreview_Selecting: View {
    @State private var mode: ChatsMode = .selecting
    var body: some View {
        ChatsTopMenu(mode: $mode, clearSelection: {})
            .padding()
            .background(Color(.systemBackground))
    }
}

#Preview("Selecting") {
    ChatsTopMenuPreview_Selecting()
}
