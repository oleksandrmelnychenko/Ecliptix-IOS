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
    @State private var scrollToBottomTick = 0
    
    
    @State private var headerHeight: CGFloat = 0
    @State private var bottomHeight: CGFloat = 0
    private var barHeight: CGFloat { max(headerHeight, bottomHeight) + 30 }

    init(chatName: String, seed: [ChatMessage] = []) {
        self.chatName = chatName
        _vm = StateObject(wrappedValue: ChatViewModel(seed: seed))
    }

    var body: some View {
        ZStack(alignment: .top) {
            ChatHeader(
                chatName: chatName,
                subtitle: "last seen recently",
                isSelecting: vm.isSelecting,
                selectedCount: vm.selectionCount,
                onBack: { dismiss() },
                onShowInfo: { vm.showChatInfo = true },
                onClearChat: {},
                onCancelSelection: { vm.clearSelection() }
            )
            .frame(height: barHeight, alignment: .top)
            .background(
                GeometryReader { g in
                    Color.clear.preference(key: HeaderHeightKey.self, value: g.size.height)
                }
            )
            .zIndex(10)

            ChatBodyView(vm: vm, menuTarget: $menuTarget, scrollToBottomTick: $scrollToBottomTick)
                .padding(.top, barHeight)
            

        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ChatBottom(
                isSelecting: $vm.isSelecting,
                messageText: $vm.messageText,
                onDeleteSelected: vm.deleteSelected,
                onForwardSelected: vm.forwardSelected,
                onSend: {
                    vm.send()
                    if !vm.isAtBottom {
                        scrollToBottomTick += 1
                    }
                },
                onChoosePhoto: { vm.showPhotoPicker = true },
                onTakePhoto: { vm.showCamera = true },
                onAttachFile: { vm.showDocumentPicker = true },
                onSendLocation: {  },
                onSendContact: {}
            )
            .frame(height: barHeight)
            .background(
                GeometryReader { g in
                    Color.clear.preference(key: BottomHeightKey.self, value: g.size.height)
                }
            )
            .background(.ultraThinMaterial)
        }
        .onPreferenceChange(HeaderHeightKey.self) { headerHeight = $0 }
        .onPreferenceChange(BottomHeightKey.self) { bottomHeight = $0 }
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $vm.showChatInfo) { ChatInfoView(chatName: chatName) }
        .sheet(item: $vm.forwardingMessage) { msg in
            ChatsOverviewView(
                allowsMultipleSelection: true,
                
                onPick: { chats in
                    chats.forEach {
                        vm.forward(msg, to: .init(
                            id: $0.id,
                            name: $0.name,
                            lastMessage: $0.lastMessage,
                            unread: $0.unread,
                            lastDate: $0.lastDate)
                        )
                    }
                    vm.forwardingMessage = nil
                },
                onCancel: { vm.forwardingMessage = nil }
            )
        }
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
        .overlay(alignment: .bottom) {
            if let o = vm.overlay {
                VStack(spacing: 6) {
                    switch o {
                    case .reply(let m):
                        ReplyPreview(message: m) { vm.clearOverlay() }
                            .background(
                                GeometryReader { g in
                                    Color.clear.preference(key: BottomHeightKey.self, value: g.size.height)
                                }
                            )
                            .background(.ultraThinMaterial)
                    case .edit(let m):
                        EditPreview(message: m) { vm.clearOverlay() }
                            .background(
                                GeometryReader { g in
                                    Color.clear.preference(key: BottomHeightKey.self, value: g.size.height)
                                }
                            )
                            .background(.ultraThinMaterial)
                    }
                }
                .padding(.bottom, barHeight + 12)
                .ignoresSafeArea(.container, edges: .bottom)
            }

        }
        .overlay {
            MenuBackdropOverlay(
                menuTarget: $menuTarget,
                onReply: { vm.onReply($0) },
                onForward:{ vm.startForwarding($0) },
                onCopy: { vm.copy($0) },
                onDelete: { vm.delete($0) },
                onEdit: { vm.edit($0) },
                onSelect: { vm.beginSelection(with: $0.id) }
            )
        }
    }
}

private struct HeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
private struct BottomHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}


#Preview {
    ChatView(chatName: "Roman")
}
