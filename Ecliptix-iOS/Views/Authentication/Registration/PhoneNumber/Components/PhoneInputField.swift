//
//  PhoneInputField.swift
//  Ecliptix-iOS-Views
//
//  Created by Oleksandr Melnechenko on 02.06.2025.
//


import SwiftUI

struct PhoneInputField: View {
    @Binding var phoneNumber: String

    var body: some View {
        TextField("", text: $phoneNumber)
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
            .autocapitalization(.none)
            .padding(.horizontal, 8)
            .accessibilityLabel(Strings.PhoneNumber.phoneFieldLabel)
            .accessibilityHint(Strings.PhoneNumber.phoneFieldHint)
            .onChange(of: phoneNumber) { _, newValue in
                let sanitized = sanitizePhoneNumber(newValue)
                if sanitized != phoneNumber {
                    phoneNumber = sanitized
                }
            }
            .onAppear {
                if phoneNumber.isEmpty {
                    phoneNumber = "+"
                } else {
                    phoneNumber = sanitizePhoneNumber(phoneNumber)
                }
            }
            .frame(height: 30)
    }

    private func sanitizePhoneNumber(_ input: String) -> String {
        var result = input

        // Ensure it starts with +
        if !result.hasPrefix("+") {
            result = "+" + result
        }

        // Keep only '+' at the start and digits elsewhere
        let plus = "+"
        let digits = result.dropFirst().filter { $0.isWholeNumber }

        return plus + digits
    }
}



#Preview {
    struct PhoneInputFieldPreviewWrapper: View {
        @State private var phoneCode = "+"
        @State private var phoneNumber = ""

        var body: some View {
            PhoneInputField(
//                phoneCode: $phoneCode,
                phoneNumber: $phoneNumber
            )
            .padding()
        }
    }
    
    return PhoneInputFieldPreviewWrapper()
}

