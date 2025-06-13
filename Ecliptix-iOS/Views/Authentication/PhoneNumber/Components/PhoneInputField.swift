//
//  PhoneInputField.swift
//  Ecliptix-iOS-Views
//
//  Created by Oleksandr Melnechenko on 02.06.2025.
//


import SwiftUI

struct PhoneInputField: View {
    var phoneCode: String
    @Binding var phoneNumber: String
    var isLoading: Bool
    var onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Text(phoneCode)
                .foregroundColor(.black)
                .frame(width: 50, alignment: .center)
                .padding(.horizontal, 8)
            
            Divider()
            
            TextField(Strings.PhoneNumber.Buttons.sendCode, text: $phoneNumber)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .autocapitalization(.none)
                .padding(.horizontal, 8)
                .accessibilityLabel(Strings.PhoneNumber.phoneFieldLabel)
                .accessibilityHint(Strings.PhoneNumber.phoneFieldHint)
                .onSubmit {
                    if !phoneNumber.isEmpty {
                        onSubmit()
                    }
                }
        }
        .frame(height: 50)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    struct PhoneInputFieldPreviewWrapper: View {
        @State private var phoneNumber = ""
        @State private var navigate = false
        @State private var isLoading = false
        let selectedCountry = Country(name: "Ukraine", phoneCode: "+380", flag: "ua")
        
        var body: some View {
            VStack(spacing: 20) {
                PhoneInputField(
                    phoneCode: selectedCountry.phoneCode,
                    phoneNumber: $phoneNumber,
                    isLoading: isLoading,
                    onSubmit: {
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isLoading = false
                            navigate = true
                        }
                    }
                )
                
                Text("Navigate: \(navigate ? "Yes" : "No")")
            }
            .padding()
        }
    }
    
    return PhoneInputFieldPreviewWrapper()
}

