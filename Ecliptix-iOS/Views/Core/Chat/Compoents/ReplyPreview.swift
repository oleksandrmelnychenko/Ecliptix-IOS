//
//  ReplyPreview.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 12.08.2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ReplyPreview: View {
    let message: ChatMessage
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                
            }, label: {
                Image(systemName: "arrowshape.turn.up.left")
                    .font(.title3)
                    .foregroundStyle(.blue)
            })
            
            Divider()
                .frame(width: 2, height: 36)
                .overlay(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Replying to")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(message.text)
                    .font(.subheadline)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

#Preview {
    VStack {
        ReplyPreview(
            message:  .init(text: "Якщо не вміщується — вниз",   side: .outgoing, time: "16:00", createdAt: Date().addingTimeInterval(-60*29)),
            onCancel: {})
    }
}
