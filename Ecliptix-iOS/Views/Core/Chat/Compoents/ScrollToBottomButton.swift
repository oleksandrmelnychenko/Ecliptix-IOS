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
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(10)
            }
        }
    }
}

#Preview {
    ScrollToBottomButton(isVisible: true, action: {})
}
