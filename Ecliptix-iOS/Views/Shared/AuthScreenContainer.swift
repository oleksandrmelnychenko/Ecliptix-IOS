//
//  AuthScreenContainer.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 16.06.2025.
//

import SwiftUI

struct AuthScreenContainer<Content: View>: View {
    @Environment(\.dismiss) private var dismiss

    let content: Content
    let spacing: CGFloat
    let canGoBack: Bool

    init(spacing: CGFloat = 0, canGoBack: Bool = false, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.spacing = spacing
        self.canGoBack = canGoBack
    }
    
    var body: some View {
        VStack {
            ScrollView {
                HStack {
                    Spacer()
                    Image("EcliptixLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                    Spacer()
                }
                .padding(.top, 15)
                
                VStack(alignment: .leading, spacing: spacing) {
                    content
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
            }
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(.keyboard)
            
            HStack {
                Spacer()
                Text("© Horizon Dynamics LLC 2025")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Spacer()
            }
            .background(Color.white.ignoresSafeArea(edges: .bottom))
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if self.canGoBack {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("BackArrow")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .padding(12)
                            .background(Color("BackButton.Background"))
                            .clipShape(Circle())
                        
                    }
                }
            }
        }
    }
}
