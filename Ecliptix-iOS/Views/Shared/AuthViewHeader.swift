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
                .font(.title)
            
            // Subtitle
            Text(viewDescription)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
                .padding(.top, 15)
        }
    }
}
