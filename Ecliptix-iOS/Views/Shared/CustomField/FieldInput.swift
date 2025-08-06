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
            
//            if let strength = passwordStrength {
//                PasswordStrengthBar(strength: strength)
//                    .padding(.horizontal, 8)
//                    .padding(.bottom, 4)
//            }
                

            VStack(alignment: .leading, spacing: 4) {
                if self.showValidationErrors, let firstError = validationErrors.first {
                    HStack(alignment: .center) {
                        Group {
                            if let strength = self.passwordStrength {
                                Image("Validation.Lamp")
                                    .foregroundColor(Color("PasswordStrength.\(strength.styleKey)"))
                                Text("\(strength.styleKey): \(firstError.message)")
                                    .foregroundColor(Color("PasswordStrength.\(strength.styleKey)"))
                            } else {
                                Image("Validation.Lamp")
                                    .foregroundColor(Color("Validation.Error"))
                                Text(firstError.message)
                                    .foregroundColor(Color("Validation.Error"))
                            }
                        }

                        Spacer()
                    }
                    .font(.subheadline)
                    .animation(.easeInOut(duration: 0.3), value: passwordStrength)
                } else {
                    HStack(alignment: .bottom) {
                        Image("Validation.Lamp")
                            .font(.subheadline)
                        Text(self.hintText)
                        Spacer()
                    }
                    .foregroundColor(passwordStrengthColor)
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
    
    private var passwordStrengthColor: Color {
        if showValidationErrors, let strength = passwordStrength {
            return Color("PasswordStrength.\(strength.styleKey)")
        }
        
        if showValidationErrors && !validationErrors.isEmpty {
            return Color("Validation.Error")
        }
        
        return Color("Tips.Color")
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

struct PasswordStrengthBar: View {
    let strength: PasswordStrengthType

    private var color: Color {
        Color("PasswordStrength.\(strength.styleKey)")
    }

    private var width: CGFloat {
        switch strength {
        case .veryWeak:   return 0.2
        case .weak:       return 0.4
        case .good:       return 0.6
        case .strong:     return 0.8
        case .veryStrong: return 1.0
        case .invalid:    return 0.0
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 6)
                    .cornerRadius(3)

                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * width, height: 6)
                    .cornerRadius(3)
                    .animation(.easeInOut(duration: 0.4), value: strength)
            }
        }
        .frame(height: 6)
    }
}

