//
//  CustomAlertView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 06.08.2025.
//


import SwiftUI

struct CustomAlertView: View {
    let title: String
    let message: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)

            HStack {
                PrimaryButton(
                    title: "Cancel",
                    isEnabled: true,
                    isLoading: false,
                    style: .light,
                    action: onCancel)
                Spacer()
                PrimaryButton(
                    title: "Confirm",
                    isEnabled: true,
                    isLoading: false,
                    style: .dark,
                    action: onConfirm)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding(.horizontal, 40)
    }
}

#Preview {
    CustomAlertView(
        title: "Alert Title",
        message: "Alert message",
        onConfirm: {
            print("Confirm pressed")
        },
        onCancel: {
            print("Cancel pressed")
        }
    )
}
