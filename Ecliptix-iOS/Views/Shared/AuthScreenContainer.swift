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
    let canGoBack: Bool

    init(
        spacing: CGFloat = 0,
        canGoBack: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.spacing = spacing
        self.canGoBack = canGoBack
    }
    
    var body: some View {
            ScrollView {
                VStack(spacing: spacing) {
                    Logo()
                        .padding(.top, 15)
                    
                    content

                    Spacer(minLength: 60)
                }
                .padding(.horizontal)
            }
            .scrollDismissesKeyboard(.interactively)
            .gesture(
                TapGesture()
                    .onEnded { hideKeyboard() }
            )
            .navigationBarBackButtonHidden(true)
            .toolbar {
                if canGoBack {
                    ToolbarItem(placement: .navigationBarLeading) {
                        BackButton()
                    }
                }
            }
        
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
