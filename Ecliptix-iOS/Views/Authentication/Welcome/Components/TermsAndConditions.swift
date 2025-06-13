//
//  TermsAndConditions.swift
//  Ecliptix-iOS-Views
//
//  Created by Oleksandr Melnechenko on 02.06.2025.
//


import SwiftUI

struct TermsAndConditions: View {
    @Binding var agreedToTerms: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                agreedToTerms.toggle()
            }) {
                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                    .foregroundColor(agreedToTerms ? .black : .black)
                    .font(.system(size: 26))
            }
            
            Group {
                Text("I agree with ")
                + Text("User Terms And Conditions").underline()
                + Text(" and acknowledge the ")
                + Text("Privacy Notice").underline()
                + Text(" of World App provided by Tools for Humanity.")
            }
            .font(.footnote)
            .foregroundColor(.gray)
            
        }
        .accessibilityLabel("Agree to Terms and Conditions")
    }
}

#Preview {
    @Previewable @State var isAgreed = false
    
    return TermsAndConditions(agreedToTerms: $isAgreed)
}
