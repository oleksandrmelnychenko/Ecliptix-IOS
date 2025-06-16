//
//  PrimaryActionButton.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 16.06.2025.
//

import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Text(title)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .background(isEnabled ? Color.black : Color.gray)
        .foregroundColor(.white)
        .cornerRadius(10)
        .disabled(!isEnabled)
    }
}
