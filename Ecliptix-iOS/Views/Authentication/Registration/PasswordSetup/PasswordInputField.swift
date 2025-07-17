//
//  PasswordInputField.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.07.2025.
//


import SwiftUI

struct PasswordInputField: View {
    @State private var showPassword: Bool = false
    var placeholder: String = ""
    @Binding var text: String
    
    var body: some View {
        HStack {
            if showPassword {
                TextField(placeholder, text: $text)
                    .textContentType(.newPassword)
                    .font(.title3)
            } else {
                SecureField(placeholder, text: $text)
                    .textContentType(.newPassword)
                    .font(.title3)
            }
                
            
            Button(action: {
                showPassword.toggle()
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
    }
}