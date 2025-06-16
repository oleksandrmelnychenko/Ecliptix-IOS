//
//  AuthScreenContainer.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 16.06.2025.
//

import SwiftUI

struct AuthScreenContainer<Content: View>: View {
    let content: Content
    let spacing: CGFloat

    init(spacing: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.spacing = spacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .padding(.horizontal)
        .padding(.top, 100)
    }
}
