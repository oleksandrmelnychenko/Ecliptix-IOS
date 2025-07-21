//
//  PhoneNumberHeader.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 22.05.2025.
//


import SwiftUI

struct AuthViewHeader: View {
    var viewTitle: String
    var viewDescription: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Title
            Text(viewTitle)
                .font(.title2)
            
            // Subtitle
            Text(viewDescription)
                .font(.title)
                .multilineTextAlignment(.leading)
                .padding(.top, 15)
        }
    }
}

#Preview {
    AuthViewHeader(viewTitle: "Sign in", viewDescription: "Welcome back! Your personalized experience awaits.")
}
