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
    var placeholder: String = ""
    let hintText: String?
    var validationErrors: [ErrorType] = []
    
    let content: () -> Content

    init(
        title: String,
        text: Binding<String>,
        placeholder: String = "",
        hintText: String? = nil,
        validationErrors: [ErrorType] = [],
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.hintText = hintText
        self.validationErrors = validationErrors
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            VStack(spacing: 0) {
                // fix here
                HStack {
                    content()
                }
                .padding(.horizontal, 8)
                .padding(.top, 15)
                .padding(.bottom, 10)

                if let hint = hintText {
                    HStack(alignment: .bottom) {
                        Image(systemName: "lightbulb.min")
                            .foregroundColor(.black)
                            .font(.system(size: 14))

                        Text(hint)
                            .font(.system(size: 14))

                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 5)
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                if let firstError = validationErrors.first {
                    ValidationMessageView(text: firstError.rawValue)
                }
            }
            .animation(.easeInOut, value: text)
        }
    }
}

