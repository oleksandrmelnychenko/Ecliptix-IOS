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
    var passwordStrength: PasswordStrengthType? = nil

    let content: () -> AnyView

    init<Content: View>(
        placeholder: String = "",
        hintText: String = "",
        validationErrors: [ErrorType] = [],
        showValidationErrors: Binding<Bool>,
        isFocused: Binding<Bool>? = nil,
        passwordStrength: PasswordStrengthType? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._showValidationErrors = showValidationErrors
        self.placeholder = placeholder
        self.hintText = hintText
        self.validationErrors = validationErrors
        self.isFocused = isFocused
        self.passwordStrength = passwordStrength
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
                        if let passwordStrength = self.passwordStrength, passwordStrength != .invalid {
                            Text("\(passwordStrength.styleKey): \(firstError.message)")
                        } else {
                            Text(firstError.message)
                        }
                        
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
        if showValidationErrors, let strength = passwordStrength {
            return Color("PasswordStrength.\(strength.styleKey)")
        }
        
        if showValidationErrors && !validationErrors.isEmpty {
            return Color("Validation.Error")
        }

        if isFocused?.wrappedValue == true {
            return Color("Tips.Color")
        }

        return .clear
    }
    
    private var shadowColor: Color {
        if showValidationErrors, let strength = passwordStrength {
            return Color("PasswordStrength.\(strength.styleKey)").opacity(1)
        }
        
        if showValidationErrors && !validationErrors.isEmpty {
            return Color("Validation.Error").opacity(1)
        }

        if isFocused?.wrappedValue == true {
            return Color("Tips.Color").opacity(1)
        }

        return .clear
    }
    
    private var shadowRadius: CGFloat {
        if showValidationErrors && !validationErrors.isEmpty || isFocused?.wrappedValue == true || passwordStrength != nil {
            return 4
        }
        return 0
    }
}
