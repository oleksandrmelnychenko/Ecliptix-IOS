//
//  SelectionToolbar.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI

struct SelectionToolbar: ToolbarContent {
    var canAct: Bool
    var onMute: () -> Void
    var onArchive: () -> Void
    var onDelete: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button(action: onMute) {
                VStack(spacing: 4) { Image(systemName: "speaker.slash"); Text("Mute").font(.footnote) }
            }
            .disabled(!canAct)

            Spacer()

            Button(action: onArchive) {
                VStack(spacing: 4) { Image(systemName: "archivebox"); Text("Archive").font(.footnote) }
            }
            .disabled(!canAct)

            Spacer()

            Button(role: .destructive, action: onDelete) {
                VStack(spacing: 4) { Image(systemName: "trash"); Text("Delete").font(.footnote) }
            }
            .disabled(!canAct)
        }
    }
}

#Preview("Active") {
    NavigationStack {
        Text("Preview content")
            .toolbar {
                SelectionToolbar(
                    canAct: true,
                    onMute: { print("Mute") },
                    onArchive: { print("Archive") },
                    onDelete: { print("Delete") }
                )
            }
    }
}

#Preview("Disabled") {
    NavigationStack {
        Text("Preview content")
            .toolbar {
                SelectionToolbar(
                    canAct: false,
                    onMute: { },
                    onArchive: { },
                    onDelete: { }
                )
            }
    }
}
