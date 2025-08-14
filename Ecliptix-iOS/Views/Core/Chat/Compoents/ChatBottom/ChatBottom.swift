//
//  ChatBottom.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.08.2025.
//

import SwiftUI

struct ChatBottom: View {
    @Binding var isSelecting: Bool
    @Binding var messageText: String
    
    let onDeleteSelected: () -> Void
    let onForwardSelected: () -> Void
    
    let onSend: () -> Void
    let onChoosePhoto: () -> Void
    let onTakePhoto: () -> Void
    let onAttachFile: () -> Void
    let onSendLocation: () -> Void
    let onSendContact: () -> Void
    
    var body: some View {
        Group {
            if isSelecting {
                BottomMenu(
                    onDelete: onDeleteSelected,
                    onSend: {},
                    onForward: onForwardSelected
                )
            } else {
                InputBar(
                    text: $messageText,
                    onSend: onSend,
                    onChoosePhoto: onChoosePhoto,
                    onTakePhoto: onTakePhoto,
                    onAttachFile: onAttachFile,
                    onSendLocation: onSendLocation,
                    onSendContact: onSendContact
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }
}
