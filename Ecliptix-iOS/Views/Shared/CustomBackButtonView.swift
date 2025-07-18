//
//  CustomBackButtonView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 18.07.2025.
//

import SwiftUI

struct CustomBackButtonView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
        }
        .navigationBarBackButtonHidden(true) // ховаємо стандартну кнопку
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss() // діє як звичайна кнопка "Назад"
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Назад")
                    }
                }
            }
        }
    }
}
