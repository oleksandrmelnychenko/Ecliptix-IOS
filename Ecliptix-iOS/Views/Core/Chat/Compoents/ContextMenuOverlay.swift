import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ContextMenuOverlay: View {
    var body: some View {
        ZStack {
            // бекдроп: матеріал + легкий діммер
            Color.clear
                .background(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.08))
                .ignoresSafeArea()
                .onTapGesture { withAnimation(.spring()) { menuTarget = nil } }
            
            // клон бульбашки — рівно поверх оригіналу
            TextMessage(message: t.message, isLastInGroup: false)
                .scaleEffect(1.03)
                .shadow(radius: 6, y: 3)
                .position(x: bubble.midX, y: bubble.midY)
                .allowsHitTesting(false)  // тільки для виду
                .zIndex(2)
            
            // меню — під бульбашкою
            MessageActionMenu(
                onReply:  { replyingTo = t.message; menuTarget = nil },
                onForward:{ forward(t.message);     menuTarget = nil },
                onCopy:   { UIPasteboard.general.string = t.message.text; menuTarget = nil },
                onDelete: { delete(t.message);      menuTarget = nil },
                onDismiss:{ withAnimation(.spring()) { menuTarget = nil } }
            )
            .frame(width: menuSize.width, height: menuSize.height)
            .position(x: centerX, y: centerY)
            .transition(.scale.combined(with: .opacity))
            .zIndex(3)
        }
    }
}