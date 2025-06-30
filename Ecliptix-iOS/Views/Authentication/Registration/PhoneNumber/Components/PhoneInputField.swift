//
//  PhoneInputField.swift
//  Ecliptix-iOS-Views
//
//  Created by Oleksandr Melnechenko on 02.06.2025.
//


import SwiftUI

public enum PhoneFieldFocus {
    case code
    case number
}

struct PhoneInputField: View {
    @Binding var phoneCode: String
    @Binding var phoneNumber: String
    @FocusState private var focusedField: PhoneFieldFocus?

    var body: some View {
        HStack(spacing: 0) {
            TextField("+", text: $phoneCode)
                .keyboardType(.phonePad)
                .frame(width: 70)
                .padding(.horizontal, 8)
                .foregroundColor(.black)
                .focused($focusedField, equals: .code)
                .onChange(of: phoneCode) { _, newValue in
                    let digits = newValue.filter { $0.isNumber }
                    let limitedDigits = String(digits.prefix(3))
                    phoneCode = "+" + limitedDigits

                    if limitedDigits.count == 3 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            focusedField = .number
                        }
                    }
                }

            Divider()

            TextField("", text: $phoneNumber)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .autocapitalization(.none)
                .padding(.horizontal, 8)
                .accessibilityLabel(Strings.PhoneNumber.phoneFieldLabel)
                .accessibilityHint(Strings.PhoneNumber.phoneFieldHint)
                .focused($focusedField, equals: .number)
                .onChange(of: phoneNumber) { _, newValue in
                    if newValue.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            focusedField = .code
                        }
                    }
                }
        }
        .frame(height: 30)
        .onAppear {
            focusedField = .code
        }
    }
}


#Preview {
    struct PhoneInputFieldPreviewWrapper: View {
        @State private var phoneCode = "+"
        @State private var phoneNumber = ""

        var body: some View {
            PhoneInputField(
                phoneCode: $phoneCode,
                phoneNumber: $phoneNumber
            )
            .padding()
        }
    }
    
    return PhoneInputFieldPreviewWrapper()
}

