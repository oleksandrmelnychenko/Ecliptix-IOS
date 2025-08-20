//
//  ChatBodyView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.08.2025.
//

import SwiftUI

struct ChatBodyView: View {
    @ObservedObject var vm: ChatViewModel
    @Binding var menuTarget: (message: ChatMessage, isLastInGroup: Bool, frame: CGRect)?
    @Binding var scrollToBottomTick: Int

    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    MessageList(
                        messages: $vm.messages,
                        onLongPressWithFrame: { msg, isLast, frame in
                            if vm.isSelecting {
                                vm.toggleSelection(msg.id)
                            } else {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                    menuTarget = (msg, isLast, frame)
                                }
                            }
                        },
                        spaceName: vm.scrollSpace,
                        bottomAnchorId: vm.bottomAnchorId,
                        onBottomVisibilityChange: { visible in
                            vm.setBottomVisible(visible)
                        },
                        onToggleSelect: { vm.toggleSelection($0) },
                        isSelected: { vm.selected.contains($0) },
                        isSelecting: vm.isSelecting,
                        
                    )
                    .onChange(of: vm.messages.count) {
                        if vm.isAtBottom {
                            withAnimation(.easeOut(duration: 0.22)) {
                                proxy.scrollTo(vm.bottomAnchorId, anchor: .bottom)
                            }
                        }
                    }

//                    Divider()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                ScrollToBottomButton(isVisible: !vm.isAtBottom) {
                    vm.isAtBottom = true
                    jumpThenAnimateToBottom(proxy)
                }
                .padding(.trailing, 12)
                .padding(.bottom, 60)
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: vm.isAtBottom)
            .onChange(of: scrollToBottomTick) {
                jumpThenAnimateToBottom(proxy)
            }
        }
    }
    
    private func jumpThenAnimateToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            proxy.scrollTo(vm.bottomAnchorId, anchor: .bottom)

            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    proxy.scrollTo(vm.bottomAnchorId, anchor: .bottom)
                }
            }
        }
    }
}
