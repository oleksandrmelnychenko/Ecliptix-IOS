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
                validationTextRow()
            }
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.bottom)
        }
        .background(Color("TextBox.BackgroundColor"))
        .foregroundStyle(Color("TextBox.ForegroundColor"))
        .cornerRadius(10)
        .shadow(color: shadowColor, radius: shadowRadius)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(borderColor, lineWidth: 1.5)
                
                .animation(.easeInOut(duration: 0.25), value: animationTrigger)
        )
    }

    @ViewBuilder
    private func validationTextRow() -> some View {
        HStack(alignment: .center) {
            Image("Validation.Lamp")
                .font(.subheadline)
                .foregroundColor(validationColor)

            Text(validationMessage)
                .foregroundColor(validationColor)

            Spacer()
        }
        .font(.subheadline)
        .animation(.easeInOut(duration: 0.3), value: passwordStrength)
    }

    private var hasErrors: Bool {
        showValidationErrors && !validationErrors.isEmpty
    }

    private var validationColor: Color {
        if let strength = passwordStrength, showValidationErrors {
            return Color("PasswordStrength.\(strength.styleKey)")
        } else if hasErrors {
            return Color("Validation.Error")
        } else {
            return Color("Tips.Color")
        }
    }

    private var validationMessage: String {
        if showValidationErrors, let first = validationErrors.first {
            if let strength = passwordStrength {
                return "\(strength.styleKey): \(first.message)"
            } else {
                return first.message
            }
        }
        return hintText
    }

    private var animationTrigger: Bool {
        showValidationErrors || (isFocused?.wrappedValue == true)
    }

    private var borderColor: Color {
        if showValidationErrors {
            if let strength = passwordStrength {
                return Color("PasswordStrength.\(strength.styleKey)")
            }

            if !validationErrors.isEmpty {
                return Color("Validation.Error")
            }
        }

        if isFocused?.wrappedValue == true {
            return Color("Tips.Color")
        }

        return .clear
    }

    private var shadowColor: Color {
        if showValidationErrors {
            if let strength = passwordStrength {
                return Color("PasswordStrength.\(strength.styleKey)")
            }

            if !validationErrors.isEmpty {
                return Color("Validation.Error")
            }
        }

        if isFocused?.wrappedValue == true {
            return Color("Tips.Color")
        }

        return .clear
    }

    private var shadowRadius: CGFloat {
        (hasErrors || isFocused?.wrappedValue == true || passwordStrength != nil) ? 4 : 0
    }
}
