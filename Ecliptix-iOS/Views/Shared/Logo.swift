//
//  Logo.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 21.07.2025.
//

import SwiftUI

struct Logo: View {
    
    var body: some View {
        HStack {
            Spacer()
            Image("EcliptixLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            Spacer()
        }
    }
    
}
