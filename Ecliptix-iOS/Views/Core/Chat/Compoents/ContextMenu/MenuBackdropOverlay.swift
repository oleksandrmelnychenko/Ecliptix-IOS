//
//  MenuBackdropOverlay.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.08.2025.
//

import SwiftUI


struct MenuBackdropOverlay: View {
    @Binding var menuTarget: (message: ChatMessage, isLastInGroup: Bool, frame: CGRect)?
    var onReply: (ChatMessage) -> Void
    var onForward: (ChatMessage) -> Void
    var onCopy: (ChatMessage) -> Void
    var onDelete: (ChatMessage) -> Void
    var onEdit: ((ChatMessage) -> Void)?
    

    var body: some View {
        Group {
            if let t = menuTarget {
                GeometryReader { geo in
                    let container = geo.frame(in: .global)
                    
                    let isUpperHalf = self.isMessageUpperHalf(frame: t.frame, container: container)

                    let bubbleTop = snapToPixel(frame: t.frame, container: container)

                    ZStack {
                        Color.clear
                            .background(.ultraThinMaterial)
                            .overlay(Color.black.opacity(0.08))
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                    menuTarget = nil
                                }
                            }

                        if isUpperHalf {
                            ContextMenuOverlay(
                                textMessage: .constant(
                                    TextMessage(message: t.message, isLastInGroup: t.isLastInGroup)
                                ),
                                onReply: { _ in onReply(t.message);  menuTarget = nil },
                                onForward: { _ in onForward(t.message); menuTarget = nil },
                                onCopy: {
                                    _ in onCopy(t.message);
                                    menuTarget = nil
                                },
                                onDelete: { _ in onDelete(t.message); menuTarget = nil },
                                onEdit: onEdit.map { handler in
                                        { _ in
                                            handler(t.message)
                                            menuTarget = nil
                                        }
                                    },
                                anchored: true
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .padding(.top, bubbleTop)
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            ContextMenuOverlay(
                                textMessage: .constant(
                                    TextMessage(message: t.message, isLastInGroup: t.isLastInGroup)
                                ),
                                onReply:  { _ in onReply(t.message);  menuTarget = nil },
                                onForward:{ _ in onForward(t.message); menuTarget = nil },
                                onCopy:   { _ in
                                    onCopy(t.message)
                                    menuTarget = nil
                                },
                                onDelete: { _ in onDelete(t.message); menuTarget = nil },
                                onEdit: onEdit.map { handler in              
                                    { _ in
                                        handler(t.message)
                                        menuTarget = nil
                                    }
                                },
                                anchored: false
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .animation(.spring(response: 0.32, dampingFraction: 0.86),
                           value: menuTarget != nil)
            }
        }
    }

    private func snapToPixel(frame: CGRect, container: CGRect) -> CGFloat {
        return frame.minY + container.minY
    }
    
    private func isMessageUpperHalf(frame: CGRect, container: CGRect) -> Bool {
        let frameHalfLength = frame.height * 0.5
        let midY = frame.minY + container.minY + frameHalfLength
        let isUpperHalf = midY < (container.height + container.minY) * 0.5
        
        return isUpperHalf
    }
}
