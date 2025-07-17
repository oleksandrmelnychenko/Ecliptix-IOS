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
        textField.backgroundColor = .systemGray6
        textField.layer.cornerRadius = 8
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []
        
        
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
