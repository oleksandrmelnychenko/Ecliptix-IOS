import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ReplyPreview: View {
    let message: ChatMessage
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Rectangle().fill(Color.blue).frame(width: 3).cornerRadius(1.5)
            VStack(alignment: .leading, spacing: 2) {
                Text("Replying to").font(.caption).foregroundColor(.gray)
                Text(message.text).font(.subheadline).lineLimit(1)
            }
            Spacer()
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
    }
}