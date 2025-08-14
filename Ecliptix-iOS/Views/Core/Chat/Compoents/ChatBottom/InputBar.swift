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
    var onSendLocation: () -> Void
    var onSendContact: () -> Void

    @State private var trailingMode: TrailingMode = .mic
    private var hasText: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    enum TrailingMode {
        case mic, camera
        mutating func toggle() { self = (self == .mic) ? .camera : .mic }
    }

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                Button("Choose Photo", action: onChoosePhoto)
                Button("Take Photo", action: onTakePhoto)
                Button("Send Location", action: onSendLocation)
                Button("Send Contact", action: onSendContact)
                Button("Attach Document", action: onAttachFile)
            } label: {
                Image(systemName: "plus.circle")
                    .font(.title)
                    .foregroundColor(.blue)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Add attachment")
            }

            HStack {
                TextField("Message...", text: $text)
                    .disableAutocorrection(true)
                    .submitLabel(.send)
                    .onSubmit {
                        if hasText { onSend() }
                    }

                Image(systemName: "document")
            }
            .padding(10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Trailing action
            Group {
                if hasText {
                    Button(action: onSend) {
                        Image(systemName: "paperplane.fill")
                            .rotationEffect(.degrees(45))
                    }
                    .accessibilityLabel("Send")
                } else {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            trailingMode.toggle()
                        }
                    } label: {
                        Image(systemName: trailingMode == .mic ? "microphone" : "circle.square")
                    }
                    .accessibilityLabel(trailingMode == .mic ? "Microphone" : "Camera")
                }
            }
            .foregroundColor(.blue)
            .transition(.scale.combined(with: .opacity))
        }
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
        },
        onSendLocation: {
            print("On send Location")
        },
        onSendContact: {
            print("On send Contact")
        })
}
