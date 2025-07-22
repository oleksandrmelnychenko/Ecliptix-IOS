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
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    AuthViewHeader(
        viewTitle: "Sign in",
        viewDescription: "Welcome back! Your personalized experience awaits.")
        .padding(.horizontal)
        .padding(.bottom)
        
    AuthViewHeader(
        viewTitle: "Phone number",
        viewDescription: "Please confirm your country code and phone number")
    .padding(.horizontal)
}
