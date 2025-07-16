//
//  TermsAndConditions.swift
//  Ecliptix-iOS-Views
//
//  Created by Oleksandr Melnechenko on 02.06.2025.
//


import SwiftUI

struct TermsAndConditions: View {
    @Binding var agreedToTerms: Bool
    var onTermsTapped: (() -> Void)? = nil
    var onPrivacyTapped: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Button(action: {
                agreedToTerms.toggle()
            }) {
                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                    .foregroundColor(.black)
                    .font(.system(size: 24))
            }
            .accessibilityLabel("Agree to Terms and Conditions")
            .accessibilityValue(agreedToTerms ? "Checked" : "Unchecked")
            .accessibilityAddTraits(.isButton)

            termsText
        }
        .accessibilityLabel("Agree to Terms and Conditions")
    }
    
    @ViewBuilder
    private var termsText: some View {
        Text(makeInteractiveText())
            .font(.footnote)
            .foregroundColor(.gray)
            .onOpenURL { url in
                switch url.absoluteString {
                case "app://terms":
                    onTermsTapped?()
                case "app://privacy":
                    onPrivacyTapped?()
                default:
                    break
                }
            }
    }
    
    private func makeInteractiveText() -> AttributedString {
        var str = AttributedString("I agree with User Terms and Conditions and acknowledge the Privacy Notice of World App provided by Tools for Humanity.")
        
        if let range = str.range(of: "User Terms and Conditions") {
            str[range].foregroundColor = .blue
            str[range].underlineStyle = .single
            str[range].link = URL(string: "https://developer.apple.com/documentation/swift/dictionary")
        }
        
        if let range = str.range(of: "Privacy Notice") {
            str[range].foregroundColor = .blue
            str[range].underlineStyle = .single
            str[range].link = URL(string: "https://developer.apple.com/documentation/swift/dictionary")
        }
        
        return str
    }
}

#Preview {
    @Previewable @State var isAgreed = false
    return TermsAndConditions(
        agreedToTerms: $isAgreed,
        onTermsTapped: { print("Terms tapped") },
        onPrivacyTapped: { print("Privacy tapped") }
    )
    .padding()
}
