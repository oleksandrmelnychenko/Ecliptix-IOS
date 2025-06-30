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
                .foregroundColor(.red)
                .font(.caption)
            Text(text)
                .font(.footnote)
                .foregroundColor(.red)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}