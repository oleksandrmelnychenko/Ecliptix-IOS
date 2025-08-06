//
//  BackButton.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 21.07.2025.
//

import SwiftUI

struct BackButton: View {
    @EnvironmentObject private var navigation: NavigationService
    
    var body: some View {
        Button(action: { navigation.pop() }) {
            Image("BackArrow")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .padding(12)
                .background(Color("BackButton.BackgroundColor"))
                .clipShape(Circle())
        }
    }
}
