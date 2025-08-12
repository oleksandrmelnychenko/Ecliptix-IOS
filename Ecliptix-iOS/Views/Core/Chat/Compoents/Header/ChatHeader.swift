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
    var onBack: () -> Void
    var onInfo: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 0) {
                    Image(systemName: "chevron.backward")
                        .font(.title)
                        .bold()
                    
                    Text("Back")
                }
            }

            ChatTitleButton(
                title: chatName,
                subtitle: "last seen today at 15:34",
                onTap: onInfo
            )
            .frame(maxWidth: .infinity)

            AvatarButton(size: 36, onTap: onInfo)
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ChatHeader(
        chatName: "Demo chat",
        onBack: {
            print("on back tapped")
        },
        onInfo: {
            print("on info tapped")
        }
    )
}
