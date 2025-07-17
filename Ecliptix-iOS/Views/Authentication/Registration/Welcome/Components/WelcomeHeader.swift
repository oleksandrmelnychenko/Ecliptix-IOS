//
//  WelcomeHeader.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 12.06.2025.
//


import SwiftUI

struct WelcomeHeader: View {
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // App title
//            Text(String(localized: "Ecliptix"))
//                .font(.largeTitle)
//                .fontWeight(.bold)
            
            // Subtitle
//            Text(String(localized: "Master the architecture of your mind"))
//                .font(.body)
//                .foregroundColor(.gray)
//                .multilineTextAlignment(.leading)
//                .padding(.top, 15)
            
            Image("Title")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 40)
                
            Image("Subtitle")
                .resizable()
                .scaledToFit()
                .frame(width: 350, height: 60)
        }
    }
}

#Preview {
    return WelcomeHeader()
}
