//
//  OneTimeCodeTextField.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//


import SwiftUI

struct OneTimeCodeTextField: UIViewRepresentable {
    @Binding var text: String
    var isFirstResponder: Bool
    var onBackspace: () -> Void
    var onInput: (String) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = SizedTextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.textAlignment = .center
        textField.font = UIFont.systemFont(ofSize: 24)
        textField.backgroundColor = UIColor(named: "TextBox.BackgroundColor")
        textField.textColor = UIColor(named: "TextBox.ForegroundColor")
        textField.layer.cornerRadius = 8
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        if isFirstResponder && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFirstResponder && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
    
    class SizedTextField: UITextField {
        override var intrinsicContentSize: CGSize {
            return CGSize(width: 44, height: 55)
        }
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: OneTimeCodeTextField

        init(_ parent: OneTimeCodeTextField) {
            self.parent = parent
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""

            if string.isEmpty { // backspace
                if !currentText.isEmpty {
                    
                    parent.onInput(VerificationCodeViewModel.emptySign)
                    
                    parent.onBackspace()
                } else {
                    parent.onBackspace()
                }
                return false
            }

            
            guard string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else {
                return false
            }

            parent.onInput(String(string.prefix(1)))
            return false
        }

    }
}

#Preview {
    OneTimeCodeTextFieldPreview()
}

private struct OneTimeCodeTextFieldPreview: View {
    @State private var code: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedField: Int?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<6, id: \.self) { index in
                OneTimeCodeTextField(
                    text: $code[index],
                    isFirstResponder: focusedField == index,
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
