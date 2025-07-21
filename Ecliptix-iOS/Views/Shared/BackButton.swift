//
//  BackButton.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 21.07.2025.
//

import SwiftUI

struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button(action: { dismiss() }) {
            Image("BackArrow")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .padding(12)
                .background(Color("BackButton.Background"))
                .clipShape(Circle())
        }
    }
}
