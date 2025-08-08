//
//  SearchBar.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 07.08.2025.
//


import SwiftUI

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search", text: $text)
                .textFieldStyle(.plain)
                .disableAutocorrection(true)
                .autocapitalization(.none)

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray5))
        .cornerRadius(10)
    }
}