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
            Text(Strings.Welcome.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Subtitle
            Text(Strings.Welcome.description)
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
