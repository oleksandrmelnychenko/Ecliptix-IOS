//
//  PasswordFieldView.swift
//  Ecliptix-iOS-Views
//
//  Created by Oleksandr Melnechenko on 02.06.2025.
//


import SwiftUI

struct PasswordFieldView: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var validationErrors: [PasswordValidationError] = []

    @State private var showPassword: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            HStack {
                if showPassword {
                    TextField(placeholder, text: $text)
                        .textContentType(.newPassword)
                } else {
                    SecureField(placeholder, text: $text)
                        .textContentType(.newPassword)
                }

                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)

            // Validation errors
            VStack(alignment: .leading, spacing: 4) {
                ForEach(validationErrors) { error in
                    ValidationMessageView(text: error.rawValue)
                }
            }
            .animation(.easeInOut, value: text)
        }
    }
}


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

struct PasswordFieldView_Previews: PreviewProvider {
    @State static var password = ""

    static var previews: some View {
        PasswordFieldView(title: "Password", text: $password, placeholder: "Enter password")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
