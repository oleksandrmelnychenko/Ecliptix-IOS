//
//  FieldInput.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

import SwiftUI

struct FieldInput<ErrorType: ValidationError>: View {
    @Binding var showValidationErrors: Bool
    var placeholder: String = ""
    let hintText: String
    var validationErrors: [ErrorType] = []
    var isFocused: Binding<Bool>?

    let content: () -> AnyView

    init<Content: View>(
        placeholder: String = "",
        hintText: String = "",
        validationErrors: [ErrorType] = [],
        showValidationErrors: Binding<Bool>,
        isFocused: Binding<Bool>? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._showValidationErrors = showValidationErrors
        self.placeholder = placeholder
        self.hintText = hintText
        self.validationErrors = validationErrors
        self.isFocused = isFocused
        self.content = { AnyView(content()) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
                .padding(.horizontal, 8)
                .padding(.top, 15)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 4) {
                if self.showValidationErrors, let firstError = validationErrors.first {
                    HStack(alignment: .center) {
                        Image("Validation.Lamp")
                            .font(.subheadline)
                        Text(firstError.message)
                        Spacer()
                    }
                    .foregroundColor(Color("Validation.Error"))
                } else {
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
        }
        .background(Color("TextBox.BackgroundColor"))
        .foregroundStyle(Color("TextBox.ForegroundColor"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(borderColor, lineWidth: 1.5)
                .shadow(color: shadowColor, radius: shadowRadius)
                .animation(.easeInOut(duration: 0.25), value: animationTrigger)
        )
    }

    private var animationTrigger: Bool {
        showValidationErrors || (isFocused?.wrappedValue == true)
    }

    private var borderColor: Color {
        if showValidationErrors && !validationErrors.isEmpty {
            return Color("Validation.Error")
        } else if isFocused?.wrappedValue == true {
            return Color("Tips.Color")
        } else {
            return .clear
        }
    }

    private var shadowColor: Color {
        if showValidationErrors && !validationErrors.isEmpty {
            return Color("Validation.Error").opacity(1)
        } else if isFocused?.wrappedValue == true {
            return Color("Tips.Color").opacity(1)
        } else {
            return .clear
        }
    }

    private var shadowRadius: CGFloat {
        (showValidationErrors && !validationErrors.isEmpty) || (isFocused?.wrappedValue == true) ? 4 : 0
    }
}



//#Preview {
//    VStack(spacing: 70) {
//        FieldInputPreviewWrapper()
//        
//        FieldInputPreviewWrapper2()
//    }
//    .padding()
//    
//
//
//}
//
//
//private struct FieldInputPreviewWrapper: View {
//    @State private var showErrors = true
//    @State private var isFocused: Bool = false
//    @State private var phoneNumber: String = ""
//
//    var body: some View {
//        FieldInput<PhoneValidationError>(
//            placeholder: "Placeholder",
//            hintText: "this is hint",
//            validationErrors: [],
//            showValidationErrors: $showErrors,
//            isFocused: $isFocused, // передаємо фокус правильно
//            content: {
//                PhoneInputField(
//                    phoneNumber: $phoneNumber,
//                    placeholder: "Placeholder"
//                )
//            }
//        )
//        .frame(height: 44)
//    }
//}
//
//private struct FieldInputPreviewWrapper2: View {
//    @State private var showErrors = true
//    @State private var isFocused: Bool = false
//    @State private var phoneNumber: String = ""
//
//    var body: some View {
//        FieldInput<PhoneValidationError>(
//            placeholder: "Placeholder",
//            hintText: "this is hint",
//            validationErrors: [PhoneValidationError.cannotBeEmpty],
//            showValidationErrors: $showErrors,
//            isFocused: $isFocused, // передаємо фокус правильно
//            content: {
//                PhoneInputField(
//                    phoneNumber: $phoneNumber,
//                    placeholder: "Placeholder",
//                )
//            }
//        )
//        .frame(height: 44)
//    }
//}
