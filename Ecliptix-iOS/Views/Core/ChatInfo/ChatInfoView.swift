//
//  ChatInfoView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//

import SwiftUI

struct ChatInfoView: View {
    let chatName: String
    @State private var isMuted = false

    var body: some View {
        NavigationStack {
            List {
                // Header
                HStack(spacing: 16) {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(chatName).font(.title3).bold()
                        Text("last seen today at 15:34")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)

                Section {
                    Toggle(isOn: $isMuted) {
                        Label("Mute notifications", systemImage: "bell.slash")
                    }
                    NavigationLink {
                        Text("Search in chat (WIP)")
                    } label: {
                        Label("Search in chat", systemImage: "magnifyingglass")
                    }
                    NavigationLink {
                        Text("Media, Links and Docs (WIP)")
                    } label: {
                        Label("Media, Links and Docs", systemImage: "photo.on.rectangle.angled")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        // Block user
                    } label: { Label("Block", systemImage: "hand.raised") }

                    Button(role: .destructive) {
                        // Delete chat
                    } label: { Label("Delete chat", systemImage: "trash") }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ChatInfoView(chatName: "Demo Chat")
}
