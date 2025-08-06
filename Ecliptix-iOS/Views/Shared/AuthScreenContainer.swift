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
    
    @State private var showLanguageAlert = false
    @State private var suggestedLanguage: SupportedLanguage?
    
    @Binding var showCustomAlert: Bool
    @Binding var customAlertTitle: String?
    @Binding var customAlertMessage: String?
    let customAlertAction: (() -> Void)?
    
    @StateObject private var networkMonitor = NetworkMonitor()
    @EnvironmentObject var localizationService: LocalizationService
    
    init(
        spacing: CGFloat = 0,
        canGoBack: Bool = false,
        showCustomAlert: Binding<Bool> = .constant(false),
        customAlertTitle: Binding<String?> = .constant(nil),
        customAlertMessage: Binding<String?> = .constant(nil),
        customAlertAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self._showCustomAlert = showCustomAlert
        self._customAlertTitle = customAlertTitle
        self._customAlertMessage = customAlertMessage
        self.customAlertAction = customAlertAction
        self.spacing = spacing
        self.canGoBack = canGoBack
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                HStack {
                    if canGoBack {
                        BackButton()
                    }
                    Spacer()
                    LanguageMenu()
                }
                .padding()
//                .background(.ultraThinMaterial)
                .zIndex(10)
                
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
            }
            
            if showCustomAlert {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showCustomAlert = false
                        }
                    }

                CustomAlertView(
                    title: customAlertTitle ?? "Title",
                    message: customAlertMessage ?? "Message",
                    onConfirm: {
                        // Handle confirm
                        customAlertAction?()
                        
                        showCustomAlert = false
                    },
                    onCancel: {
                        // Handle cancel
                        showCustomAlert = false
                    }
                )
                .transition(.scale)
                .zIndex(100)
            }
            
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
        .onAppear {
            if let mismatchLang = localizationService.checkIfSystemLanguageChanged() {
                suggestedLanguage = mismatchLang
                showLanguageAlert = true
            }
        }
        .alert("Change Language?", isPresented: $showLanguageAlert) {
            Button("Yes") {
                if let lang = suggestedLanguage {
                    localizationService.setLanguage(lang)
                }
            }
            Button("No", role: .cancel) {}
        } message: {
            Text("Your system language is \(suggestedLanguage?.displayName ?? ""). Would you like to switch?")
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            if isConnected {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        bannerOffset = -40
                        bannerOpacity = 0
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showConnectionView = false
                    }
                }
            } else {
                showConnectionView = true
                bannerOffset = -20
                bannerOpacity = 0
                bannerVisible = true

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
