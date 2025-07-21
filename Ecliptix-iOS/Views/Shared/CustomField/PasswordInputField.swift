//
//  PasswordInputField.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.07.2025.
//


import SwiftUI

struct PasswordInputField: View {
    var placeholder: String = ""
    var isNewPassword: Bool = false
    @Binding var showPassword: Bool
    @Binding var text: String
    
    var body: some View {
        HStack {
            Group {
                if self.showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textContentType(self.isNewPassword ? .newPassword : .password)
            .font(.title3)

            Button(action: {
                showPassword.toggle()
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
    }
}
