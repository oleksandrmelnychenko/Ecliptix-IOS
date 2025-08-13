//
//  ScrollToBottomButton.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.08.2025.
//

import SwiftUI

struct ScrollToBottomButton: View {
    let isVisible: Bool
    let action: () -> Void

    var body: some View {
        Group {
            if isVisible {
                Button(action: action) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .shadow(radius: 2, y: 1)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(10)
            }
        }
    }
}
