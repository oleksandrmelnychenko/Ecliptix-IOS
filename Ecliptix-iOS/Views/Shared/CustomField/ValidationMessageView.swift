//
//  ValidationMessageView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 16.06.2025.
//


import SwiftUI

struct ValidationMessageView: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "xmark.circle.fill")
            Text(self.text)
            
            Spacer()
        }
        .foregroundColor(Color("Validation.Error"))
        .font(.subheadline)
        .padding(.horizontal, 8)
        .padding(.bottom, 5)
    }
}
