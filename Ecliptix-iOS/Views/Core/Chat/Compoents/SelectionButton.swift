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
                .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                .frame(width: 28, height: 28) // стабільний хіт-таргет
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}