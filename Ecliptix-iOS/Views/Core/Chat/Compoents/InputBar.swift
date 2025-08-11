//
//  InputBar.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct InputBar: View {
    @Binding var text: String
    var onSend: () -> Void
    var onChoosePhoto: () -> Void
    var onTakePhoto: () -> Void
    var onAttachFile: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                Button("Choose Photo", action: onChoosePhoto)
                Button("Take Photo", action: onTakePhoto)
                Button("Attach Document", action: onAttachFile)
            } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                    .padding(8)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Add attachment")
            }

            TextField("Message...", text: $text)
                .padding(10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .disableAutocorrection(true)

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .rotationEffect(.degrees(45))
                    .foregroundColor(.blue)
                    .font(.system(size: 22))
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

#Preview {
    @Previewable @State var previewText = "Demo text"
    InputBar(
        text: $previewText,
        onSend: {
            print("On send")
        },
        onChoosePhoto: {
            print("On choose photo")
        },
        onTakePhoto: {
            print("On take photo")
        },
        onAttachFile: {
            print("On attach file")
        })
}
