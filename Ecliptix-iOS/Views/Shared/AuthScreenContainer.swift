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

    @StateObject private var networkMonitor = NetworkMonitor()
    
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
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: spacing) {
                    Logo()
                        .padding(.top, 15)
                    
                    content

                    Spacer(minLength: 60)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
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
            .zIndex(0)
            
            if !networkMonitor.isConnected {
                Color.clear
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.001))
                    .allowsHitTesting(true)
                    .transition(.opacity)
                    .zIndex(1)

                InternetConnectionView()
                    .padding(.top, 60)
                    .transition(.move(edge: .top))
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
