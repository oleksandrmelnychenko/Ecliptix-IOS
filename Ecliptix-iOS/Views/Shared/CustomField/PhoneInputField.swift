//
//  PhoneInputField.swift
//  Ecliptix-iOS-Views
//
//  Created by Oleksandr Melnechenko on 02.06.2025.
//


import SwiftUI
import UIKit

struct PhoneInputField: UIViewRepresentable {
    @Binding var phoneNumber: String
    let placeholder: String
    var isFocused: Binding<Bool>? = nil

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PhoneInputField

        init(parent: PhoneInputField) {
            self.parent = parent
        }

        @objc func textFieldDidChangeSelection(_ textField: UITextField) {
            let rawText = textField.text ?? ""
            let digits = rawText.filter { $0.isWholeNumber }

            if digits.isEmpty {
                parent.phoneNumber = ""
                textField.text = ""
            } else {
                let formatted = "+" + digits
                if formatted != textField.text {
                    textField.text = formatted
                }
                parent.phoneNumber = formatted
            }
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFocused?.wrappedValue = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFocused?.wrappedValue = false
        }
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = .phonePad
        textField.textContentType = .telephoneNumber
        textField.autocapitalizationType = .none
        textField.font = UIFont.preferredFont(forTextStyle: .title3)
        textField.delegate = context.coordinator
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textFieldDidChangeSelection(_:)),
            for: .editingChanged
        )
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != phoneNumber {
            uiView.text = phoneNumber
        }

        if let isFocused = isFocused {
            if isFocused.wrappedValue && !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            } else if !isFocused.wrappedValue && uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}


#Preview {
    struct PhoneInputFieldPreviewWrapper: View {
        @State private var phoneCode = "+"
        @State private var phoneNumber = ""

        var body: some View {
            PhoneInputField(
                phoneNumber: $phoneNumber,
                placeholder: "Mobile Phone"
            )
            .padding()
        }
    }
    
    return PhoneInputFieldPreviewWrapper()
}

