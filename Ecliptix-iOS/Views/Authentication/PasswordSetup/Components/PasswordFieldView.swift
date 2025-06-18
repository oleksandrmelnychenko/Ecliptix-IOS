//
//  PasswordFieldView.swift
//  Ecliptix-iOS-Views
//
//  Created by Oleksandr Melnechenko on 02.06.2025.
//


import SwiftUI

struct PasswordFieldView<ErrorType: ValidationError>: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var validationErrors: [ErrorType] = []

    @State private var showPassword: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            VStack(spacing: 0) {
                HStack {
                    if showPassword {
                        TextField(placeholder, text: $text)
                            .textContentType(.newPassword)
                            .font(.system(size: 20))
                    } else {
                        SecureField(placeholder, text: $text)
                            .textContentType(.newPassword)
                            .font(.system(size: 20))
                    }
                    
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 15)
                .padding(.bottom, 10)
                
                HStack(alignment: .bottom) {
                    Image(systemName: "lightbulb.min")
                        .foregroundColor(.black)
                        .font(.system(size: 14))
                    
                    Text("8 Chars, 1 upper and 1 number")
                        .font(.system(size: 14))
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 5)
                
            }
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

struct PasswordFieldView_Previews: PreviewProvider {
    @State static var password = ""

    static var previews: some View {
        PasswordFieldView<PasswordValidationError>(
            title: "Password",
            text: $password,
            placeholder: "Enter password"
        )
//        .padding()
//        .previewLayout(.sizeThatFits)
    }
}
