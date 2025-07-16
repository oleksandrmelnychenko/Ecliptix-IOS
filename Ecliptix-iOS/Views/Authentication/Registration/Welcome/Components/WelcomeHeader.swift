//
//  WelcomeHeader.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 12.06.2025.
//


import SwiftUI

struct WelcomeHeader: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App title
            Text(String(localized: "Welcome to Ecliptix"))
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Subtitle
            Text(String(localized: "The wallet designed to make digital ID and global finance simple for all."))
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
                .padding(.top, 15)
        }
    }
}

#Preview {
    return WelcomeHeader()
}
