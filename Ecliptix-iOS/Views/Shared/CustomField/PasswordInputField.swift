//
//  PasswordInputField.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.07.2025.
//


import SwiftUI

struct SecurePasswordField: UIViewRepresentable {
    var placeholder: String
    var onCharacterAdded: ((Int, String) -> Void)?
    var onCharacterRemoved: ((Int, Int) -> Void)?
    var isFocused: Binding<Bool>? = nil

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []
        textField.isSecureTextEntry = true
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.font = UIFont.preferredFont(forTextStyle: .title3)
        context.coordinator.textField = textField
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if let isFocused = isFocused {
            if isFocused.wrappedValue && !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            } else if !isFocused.wrappedValue && uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onCharacterAdded: onCharacterAdded,
            onCharacterRemoved: onCharacterRemoved,
            isFocused: isFocused
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var textField: UITextField?
        var onCharacterAdded: ((Int, String) -> Void)?
        var onCharacterRemoved: ((Int, Int) -> Void)?
        var isFocused: Binding<Bool>?

        init(
            onCharacterAdded: ((Int, String) -> Void)?,
            onCharacterRemoved: ((Int, Int) -> Void)?,
            isFocused: Binding<Bool>? = nil
        ) {
            self.onCharacterAdded = onCharacterAdded
            self.onCharacterRemoved = onCharacterRemoved
            self.isFocused = isFocused
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""
            guard Range(range, in: currentText) != nil else { return false }

            let startIndex = range.location
            let removedCount = range.length

            if !string.isEmpty {
                onCharacterAdded?(startIndex, string)
            }

            if removedCount > 0 {
                onCharacterRemoved?(startIndex, removedCount)
            }

            return true
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            isFocused?.wrappedValue = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isFocused?.wrappedValue = false
        }
    }
}
