//
//  ChatView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 05.08.2025.
//

import SwiftUI
import PhotosUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    let chatName: String

    @StateObject private var vm: ChatViewModel
    @State private var menuTarget: (message: ChatMessage, isLastInGroup: Bool, frame: CGRect)?

    init(chatName: String, seed: [ChatMessage] = []) {
        self.chatName = chatName
        _vm = StateObject(wrappedValue: ChatViewModel(seed: seed))
    }

    var body: some View {
        ZStack(alignment: .top) {
            ChatHeader(
                chatName: chatName,
                onBack: { dismiss() },
                onInfo: { vm.showChatInfo = true }
            )
            .zIndex(10)

            ChatBodyView(vm: vm, menuTarget: $menuTarget)
                .padding(.top, 30)
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $vm.showChatInfo) { ChatInfoView(chatName: chatName) }
        .photosPicker(isPresented: $vm.showPhotoPicker, selection: $vm.selectedPhoto)
        .sheet(isPresented: $vm.showCamera) { Text("Camera not implemented") }
        .fileImporter(isPresented: $vm.showDocumentPicker, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let url): vm.selectedDocumentURL = url
            case .failure(let error): print("Document selection error: \(error.localizedDescription)")
            }
        }
        .background(
            Image("ChatBackground")
                .resizable(resizingMode: .tile)
                .interpolation(.none)
        )
        .overlay {
            MenuBackdropOverlay(
                menuTarget: $menuTarget,
                onReply:  { vm.replyingTo = $0 },
                onForward:{ vm.forward($0) },
                onCopy:   { UIPasteboard.general.string = $0.text },
                onDelete: { vm.delete($0) }
            )
        }
    }
}


#Preview {
    ChatView(chatName: "Roman")
}
