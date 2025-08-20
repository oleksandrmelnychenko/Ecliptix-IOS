//
//  ChatBubbleShape.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 12.08.2025.
//


import SwiftUI

@available(iOS 16.0, *)
struct ChatBubbleShape: Shape {
    var isFromCurrentUser: Bool
    var showTail: Bool
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let bubbleRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: rect.height
        )
        
        path.addRoundedRect(in: bubbleRect, cornerSize: .init(width: cornerRadius, height: cornerRadius))
        
        guard showTail else { return path }

        if isFromCurrentUser {
            let start = CGPoint(x: bubbleRect.maxX + 0, y: bubbleRect.maxY - 15)
            let tip = CGPoint(x: bubbleRect.maxX + 5, y: bubbleRect.maxY + 0)
            let end = CGPoint(x: bubbleRect.maxX - 15, y: bubbleRect.maxY - 5)
            
            path.move(to: start)
            path.addQuadCurve(to: tip, control: CGPoint(x: bubbleRect.maxX - 2, y: bubbleRect.maxY - 9))
            path.addQuadCurve(to: end, control: CGPoint(x: bubbleRect.maxX + 4, y: bubbleRect.maxY + 2))
            path.closeSubpath()
        } else {
            let end = CGPoint(x: bubbleRect.minX - 0,  y: bubbleRect.maxY - 15)
            let tip = CGPoint(x: bubbleRect.minX - 5, y: bubbleRect.maxY + 0)
            let start = CGPoint(x: bubbleRect.minX + 15, y: bubbleRect.maxY - 5)
            
            
            path.move(to: start)
            path.addQuadCurve(to: tip, control: CGPoint(x: bubbleRect.minX + 4, y: bubbleRect.maxY + 2))
            path.addQuadCurve(to: end, control: CGPoint(x: bubbleRect.minX + 2, y: bubbleRect.maxY - 9))
            path.addLine(to: end)
            path.closeSubpath()
        }

        return path
    }
}

struct ChatBubbleShape_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            ChatBubbleShape(isFromCurrentUser: true, showTail: true, cornerRadius: 16)
                .fill(.blue)
                .frame(width: 200, height: 80)

            ChatBubbleShape(isFromCurrentUser: false, showTail: true, cornerRadius: 16)
                .fill(.green)
                .frame(width: 200, height: 80)

            ChatBubbleShape(isFromCurrentUser: true, showTail: false, cornerRadius: 16)
                .stroke(.red, lineWidth: 2)
                .frame(width: 200, height: 80)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
