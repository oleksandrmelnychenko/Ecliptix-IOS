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
    var onSelect: (ChatMessage) -> Void
    

    var body: some View {
        Group {
            if let t = menuTarget {
                GeometryReader { geo in
                    let container = geo.frame(in: .global)
                    let anchored = isUpperHalf(frame: t.frame, in: container)
                    let topPad = topPadding(for: t.frame, in: container)

                    ZStack {
                        Color.clear
                            .background(.ultraThinMaterial)
                            .overlay(Color.black.opacity(0.01))
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                    menuTarget = nil
                                }
                            }

                        menu(for: t, anchored: anchored)
                            .frame(maxWidth: .infinity, maxHeight: .infinity,
                                   alignment: anchored ? .top : .center)
                            .if(anchored) { view in
                                view.padding(.top, topPad)
                            }
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.32, dampingFraction: 0.86), value: menuTarget != nil)
            }
        }
    }
    
    @ViewBuilder
    private func menu(
        for t: (message: ChatMessage, isLastInGroup: Bool, frame: CGRect),
        anchored: Bool
    ) -> some View {
        ContextMenuOverlay(
            textMessage: .constant(
                TextMessage(message: .constant(t.message), isLastInGroup: t.isLastInGroup)
            ),
            onReply:  { _ in onReply(t.message);  menuTarget = nil },
            onForward:{ _ in onForward(t.message); menuTarget = nil },
            onCopy:   { _ in onCopy(t.message);   menuTarget = nil },
            onDelete: { _ in onDelete(t.message); menuTarget = nil },
            onEdit: onEdit.map { handler in { _ in handler(t.message); menuTarget = nil } },
            onSelect: { _ in onSelect(t.message); menuTarget = nil },
            anchored: anchored
        )
    }

    private func isUpperHalf(frame: CGRect, in container: CGRect) -> Bool {
        frame.midY < container.midY
    }

    private func topPadding(for frame: CGRect, in container: CGRect) -> CGFloat {
        print("topPadding: \(frame.minY + container.minY)")
        return frame.minY + container.minY
    }
}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool,
                             transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
