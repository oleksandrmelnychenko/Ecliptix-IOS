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
        TextField(
            "",
            text: $phoneNumber,
            prompt: Text("Mobile number")
        )
        .keyboardType(.phonePad)
        .textContentType(.telephoneNumber)
        .autocapitalization(.none)
        .font(.title3)
        .padding(.horizontal, 8)
        .onChange(of: phoneNumber) { _, newValue in
            phoneNumber = sanitizePhoneNumber(newValue)
        }
        .frame(height: 30)
    }

    private func sanitizePhoneNumber(_ input: String) -> String {
        let digits = input.filter { $0.isWholeNumber }

        if digits.isEmpty {
            return ""
        } else {
            return "+" + digits
        }
    }
}



#Preview {
    struct PhoneInputFieldPreviewWrapper: View {
        @State private var phoneCode = "+"
        @State private var phoneNumber = ""

        var body: some View {
            PhoneInputField(
                phoneNumber: $phoneNumber
            )
            .padding()
        }
    }
    
    return PhoneInputFieldPreviewWrapper()
}

