//
//  OneTimeCodeTextField.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//


import SwiftUI

struct OneTimeCodeTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var showError: Bool
    var onBackspace: () -> Void
    var onInput: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = StyledTextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.textAlignment = .center
        textField.font = UIFont.systemFont(ofSize: 24)
        textField.backgroundColor = UIColor(named: "TextBox.BackgroundColor")
        textField.textColor = UIColor(named: "TextBox.ForegroundColor")
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1.5
        textField.layer.borderColor = UIColor.clear.cgColor
        textField.layer.shadowOpacity = 0
        textField.layer.shadowRadius = 0
        textField.layer.shadowOffset = .zero

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        // Update focus
        if isFocused && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }

        // Animate focus appearance
        UIView.animate(withDuration: 0.25) {
            if self.showError {
                uiView.layer.borderColor = UIColor(named: "Validation.Error")?.cgColor
                uiView.layer.shadowColor = UIColor(named: "Validation.Error")?.cgColor
                uiView.layer.shadowOpacity = 1
                uiView.layer.shadowRadius = 4
            } else if self.isFocused {
                uiView.layer.borderColor = UIColor(named: "Tips.Color")?.cgColor
                uiView.layer.shadowColor = UIColor(named: "Tips.Color")?.cgColor
                uiView.layer.shadowOpacity = 1
                uiView.layer.shadowRadius = 4
            } else {
                uiView.layer.borderColor = UIColor.clear.cgColor
                uiView.layer.shadowOpacity = 0
                uiView.layer.shadowRadius = 0
            }
        }
        
        if showError && !context.coordinator.hasShaken {
            shake(uiView)
            context.coordinator.hasShaken = true
        }

        if isFocused {
            context.coordinator.hasShaken = false
        }
    }

    class StyledTextField: UITextField {
        override var intrinsicContentSize: CGSize {
            CGSize(width: 44, height: 55)
        }
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: OneTimeCodeTextField
        var hasShaken: Bool = false
        
        init(_ parent: OneTimeCodeTextField) {
            self.parent = parent
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFocused = true
            DispatchQueue.main.async {
                self.parent.showError = false
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFocused = false
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""

            if string.isEmpty {
                if !currentText.isEmpty {
                    parent.onInput(VerificationCodeViewModel.emptySign)
                }
                parent.onBackspace()
                return false
            }

            guard string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else {
                return false
            }

            parent.onInput(String(string.prefix(1)))
            return false
        }
    }
    
    private func shake(_ view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-8, 8, -6, 6, -4, 4, -2, 2, 0]
        view.layer.add(animation, forKey: "shake")
    }
}


#Preview {
    OneTimeCodeTextFieldPreview()
}

private struct OneTimeCodeTextFieldPreview: View {
    @State private var code: [String] = Array(repeating: "", count: 6)
    @State private var showError: Bool = false
    @FocusState private var focusedField: Int?
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<6, id: \.self) { index in
                OneTimeCodeTextField(
                    text: $code[index],
                    isFocused: Binding(
                        get: { focusedField == index },
                        set: { newValue in
                            if newValue {
                                focusedField = index
                            }
                        }
                    ),
                    showError: $showError,
                    onBackspace: {
                        if index > 0 {
                            focusedField = index - 1
                        }
                    },
                    onInput: { newValue in
                        code[index] = newValue
                        if index < 5 {
                            focusedField = index + 1
                        }
                    }
                )
                .focused($focusedField, equals: index)
                .frame(width: 44, height: 55)
            }
        }
        .onAppear {
            focusedField = 0
        }
    }
}
