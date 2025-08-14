//
//  SelectionButton.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.08.2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct SelectionButton: View {
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(selected ? Color.black : Color.secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SelectionButton(selected: true, action: {})
}
