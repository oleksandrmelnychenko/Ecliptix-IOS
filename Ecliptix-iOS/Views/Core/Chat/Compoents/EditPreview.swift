//
//  EditPreview.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.08.2025.
//

import SwiftUI

struct EditPreview: View {
    let message: ChatMessage
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                
            }, label: {
                Image(systemName: "pencil")
                    .font(.title3)
                    .foregroundStyle(.blue)
            })
            
            Divider()
                .frame(width: 2, height: 36)
                .overlay(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Edit Message")
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
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

#Preview {
    EditPreview(
        message: .init(text: "Якщо не вміщується — вниз", side: .outgoing, time: "16:00", createdAt: Date().addingTimeInterval(-60*29)),
        onCancel: {})
}
