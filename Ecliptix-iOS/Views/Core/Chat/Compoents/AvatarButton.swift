//
//  AvatarButton.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AvatarButton: View {
    let size: CGFloat
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
    }
}

#Preview {
    AvatarButton(size: 36, onTap: {
        print("Avatar was tapped")
    })
}
