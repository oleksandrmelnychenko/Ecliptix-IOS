//
//  PhoneInputField.swift
//  Ecliptix-iOS-Views
//
//  Created by Oleksandr Melnechenko on 02.06.2025.
//


import SwiftUI

struct PhoneInputField<ErrorType: ValidationError>: View {
    let title: String
    var phoneCode: String
    @Binding var phoneNumber: String
    var placeholder: String = ""
    var validationErrors: [ErrorType] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            VStack(spacing: 0) {
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
                }
                .frame(height: 50)
                
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
            .animation(.easeInOut, value: phoneNumber)
        }
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
                PhoneInputField<PhoneValidationError>(
                    title: "Phone Number",
                    phoneCode: selectedCountry.phoneCode,
                    phoneNumber: $phoneNumber
                )
            }
            .padding()
        }
    }
    
    return PhoneInputFieldPreviewWrapper()
}

