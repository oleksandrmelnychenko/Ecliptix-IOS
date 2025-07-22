//
//  FieldInput.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

import SwiftUI

struct FieldInput<ErrorType: ValidationError, Content: View>: View {
    let title: String
    @Binding var text: String
    @Binding var showValidationErrors: Bool
    var placeholder: String = ""
    let hintText: String
    var validationErrors: [ErrorType] = []
    
    let content: () -> Content
    
    @State private var showError = false
    @State private var currentErrorText: String?
    
    init(
        title: String,
        text: Binding<String>,
        placeholder: String = "",
        hintText: String = "",
        validationErrors: [ErrorType] = [],
        showValidationErrors: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self._text = text
        self._showValidationErrors = showValidationErrors
        self.placeholder = placeholder
        self.hintText = hintText
        self.validationErrors = validationErrors
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
                .padding(.horizontal, 8)
                .padding(.top, 15)
                .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 4) {
                if self.showValidationErrors, let firstError = validationErrors.first {
                    HStack(
                        alignment: .center) {
                        Image("Validation.Lamp")
                            .font(.subheadline)
                        Text(firstError.message)
                        
                        Spacer()
                    }
                    .foregroundColor(Color("Validation.Error"))
                }
                else {
                    HStack(alignment: .bottom) {
                        Image("Validation.Lamp")
                            .font(.subheadline)
                        Text(self.hintText)
                        
                        Spacer()
                    }
                    .foregroundColor(Color("Tips.Color"))
                }
            }
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.bottom)
            .animation(.easeInOut, value: text)
        }
        .background(Color("TextBox.BackgroundColor"))
        .foregroundStyle(Color("TextBox.ForegroundColor"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    (self.showValidationErrors && !validationErrors.isEmpty)
                        ? Color("Validation.Error") : .clear,
                    lineWidth: 1.5
                )
                .animation(.easeInOut, value: showValidationErrors)
        )
    }
}

