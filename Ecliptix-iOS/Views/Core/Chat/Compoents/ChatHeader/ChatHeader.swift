//
//  ChatHeader.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 11.08.2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ChatHeader: View {
    let chatName: String
    var subtitle: String? = nil

    let isSelecting: Bool
    let selectedCount: Int

    var onBack: () -> Void
    var onShowInfo: () -> Void
    var onClearChat: () -> Void
    var onCancelSelection: () -> Void

    var body: some View {
            Group {
                if isSelecting {
                    SelectionHeader(
                        selectedCount: selectedCount,
                        onClear: onClearChat,
                        onCancel: onCancelSelection
                    )
                } else {
                    HStack(spacing: 12) {
                        Button(action: onBack) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.backward")
                                    .font(.title3.weight(.semibold))
                                Text("Back")
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Back")

                        HeaderTitleButton(
                            title: chatName,
                            subtitle: subtitle ?? "",
                            action: onShowInfo
                        )
                        .frame(maxWidth: .infinity)

                        HeaderAvatarButton(size: 36, action: onShowInfo)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .overlay(Divider(), alignment: .bottom)
        }
}

#Preview {
    ChatHeader(chatName: "Demo Chat", isSelecting: false, selectedCount: 0, onBack: {}, onShowInfo: {}, onClearChat: {}, onCancelSelection: {})
}
