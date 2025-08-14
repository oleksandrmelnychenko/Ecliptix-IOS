//
//  AvatarButton.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI

struct HeaderAvatarButton: View {
    let size: CGFloat
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
    }
}

#Preview {
    HeaderAvatarButton(size: 36, action: {
        print("Avatar was tapped")
    })
}
