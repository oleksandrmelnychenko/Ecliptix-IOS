//
//  PasswordInputField.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.07.2025.
//


import SwiftUI

//struct PasswordInputField: View {
//    var placeholder: String = ""
//    var isNewPassword: Bool = false
//    @Binding var text: String
//    
//    var body: some View {
//        HStack {
//            TextField(placeholder, text: $text)
//                .textContentType(self.isNewPassword ? .newPassword : .password)
//                .font(.title3)
//        }
//    }
//}

struct SecurePasswordField: UIViewRepresentable {
    var placeholder: String
    var onCharacterAdded: ((Int, String) -> Void)?
    var onCharacterRemoved: ((Int, Int) -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []
        textField.isSecureTextEntry = true
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        context.coordinator.lastText = ""
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(onCharacterAdded: onCharacterAdded, onCharacterRemoved: onCharacterRemoved)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var lastText: String = ""
        var onCharacterAdded: ((Int, String) -> Void)?
        var onCharacterRemoved: ((Int, Int) -> Void)?

        init(onCharacterAdded: ((Int, String) -> Void)?, onCharacterRemoved: ((Int, Int) -> Void)?) {
            self.onCharacterAdded = onCharacterAdded
            self.onCharacterRemoved = onCharacterRemoved
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""
            guard let textRange = Range(range, in: currentText) else { return false }

            let newText = currentText.replacingCharacters(in: textRange, with: string)
            let startIndex = range.location
            let removedCount = range.length

            if !string.isEmpty {
                onCharacterAdded?(startIndex, string)
            }

            if removedCount > 0 {
                onCharacterRemoved?(startIndex, removedCount)
            }

            lastText = newText
            return true
        }
    }
}


