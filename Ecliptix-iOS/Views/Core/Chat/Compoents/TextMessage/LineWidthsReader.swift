//
//  LineWidthsReader.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 20.08.2025.
//

import SwiftUI
import UIKit

struct LineWidthsReader: UIViewRepresentable {
    let text: String
    let font: UIFont
    let containerWidth: CGFloat
    var lineFragmentPadding: CGFloat = 0
    var onUpdate: ([CGFloat]) -> Void

    func makeUIView(context: Context) -> UIView { UIView(frame: .zero) }

    func updateUIView(_ uiView: UIView, context: Context) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let attr = NSAttributedString(string: text, attributes: attrs)

        let storage = NSTextStorage(attributedString: attr)
        let layout = NSLayoutManager()
        let container = NSTextContainer(
            size: CGSize(width: containerWidth, height: .greatestFiniteMagnitude)
        )
        container.lineFragmentPadding = lineFragmentPadding
        container.lineBreakMode = .byWordWrapping
        container.maximumNumberOfLines = 0

        layout.addTextContainer(container)
        storage.addLayoutManager(layout)

        let glyphRange = layout.glyphRange(for: container)
        var index = glyphRange.location
        var widths: [CGFloat] = []
        while index < NSMaxRange(glyphRange) {
            var effective = NSRange(location: 0, length: 0)
            let used = layout.lineFragmentUsedRect(forGlyphAt: index, effectiveRange: &effective)
            widths.append(used.width)
            index = NSMaxRange(effective)
        }

        DispatchQueue.main.async {
            onUpdate(widths)
        }
    }
}
