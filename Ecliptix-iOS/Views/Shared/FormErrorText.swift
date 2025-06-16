//
//  FormErrorText.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 16.06.2025.
//

import SwiftUI

struct FormErrorText: View {
    let error: String?

    var body: some View {
        if let error = error {
            Text(error)
                .foregroundColor(.red)
                .font(.footnote)
                .padding(.horizontal)
        }
    }
}
