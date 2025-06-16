//
//  KeyButton.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 16.06.2025.
//


import SwiftUI

struct KeyButton: View {
    var title: String? = nil
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.title)
                } else if let title = title {
                    Text(title)
                        .font(.title)
                }
            }
            .frame(width: 70, height: 70)
            .foregroundColor(.primary)
            .background(Color(.systemGray5))
            .clipShape(Circle())
        }
    }
}