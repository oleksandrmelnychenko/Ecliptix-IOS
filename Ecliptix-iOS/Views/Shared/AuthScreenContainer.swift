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

    @State private var showConnectionView: Bool = false
    @State private var bannerVisible: Bool = false
    @State private var bannerOffset: CGFloat = -40
    @State private var bannerOpacity: Double = 0
    
    @StateObject private var networkMonitor = NetworkMonitor()
    @EnvironmentObject var localizationService: LocalizationService
    
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    LanguageMenu()
                }
            }
            .zIndex(0)
            
            if showConnectionView {
                Color.clear
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.001))
                    .allowsHitTesting(true)
                    .transition(.opacity)
                    .zIndex(1)

                InternetConnectionView(networkMonitor: networkMonitor)
                    .padding(.top, 60)
                    .offset(y: bannerOffset)
                    .opacity(bannerOpacity)
                    .zIndex(2)
            }
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            if isConnected {
                // Залиш банер ще на трохи
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        bannerOffset = -40
                        bannerOpacity = 0
                    }

                    // Після завершення анімації повністю ховаємо View
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showConnectionView = false
                    }
                }
            } else {
                // Показуємо View
                showConnectionView = true
                bannerOffset = -20
                bannerOpacity = 0
                bannerVisible = true

                // Анімуємо заїзд
                withAnimation(.easeOut(duration: 0.4)) {
                    bannerOffset = 0
                    bannerOpacity = 1
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: networkMonitor.isConnected)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
