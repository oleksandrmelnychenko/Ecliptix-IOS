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
    let vm: ChatViewModel
    let chatName: String
    var onBack: () -> Void

    var body: some View {
        Group {
            if vm.isSelecting {
                HStack {
                    Button(
                        action: {},
                        label: {
                            Text("Clear Chat")
                        }
                    )
                    
                    Spacer()
                    
                    Text("\(vm.selectionCount) Selected")

                    Spacer()
                    
                    Button(
                        action: {},
                        label: {
                            Text("Cancel")
                        }
                    )
                }
            } else {
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
                        onTap: { vm.showChatInfo = true }
                    )
                    .frame(maxWidth: .infinity)
                    
                    AvatarButton(size: 36, onTap: { vm.showChatInfo = true })
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ChatHeader(
        vm: ChatViewModel(),
        chatName: "Demo chat",
        onBack: {
            print("on back tapped")
        }
    )
}
