//
//  PasscodeView.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 21.05.2025.
//

import SwiftUI

struct PassPhaseRegisterView: View {
    @EnvironmentObject private var navigation: NavigationService
    @EnvironmentObject private var localization: LocalizationService
    
    @StateObject private var viewModel: PassPhaseRegisterViewModel

    init() {
        _viewModel = StateObject(wrappedValue: PassPhaseRegisterViewModel())
    }

    private let columns = Array(repeating: GridItem(.flexible()), count: 3)

    var body: some View {
        AuthScreenContainer(spacing: 24, content: {
            AuthViewHeader(
                viewTitle: String(localized: "Create a Pass phase"),
                viewDescription: String(localized: "Make sure it’s something you’ll remember.")
            )

            // MARK: – PIN dots
            HStack(spacing: 20) {
                Spacer()
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < viewModel.pin.count ? Color.black : Color.clear)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                }
                Spacer()
            }
            
            FormErrorText(error: viewModel.errorMessage)
            
            // MARK: – Number pad
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(1...9, id: \.self) { number in
                    KeyButton(title: "\(number)") {
                        viewModel.append("\(number)")
                    }
                }

                KeyButton(systemImage: "faceid") { viewModel.getPassPhaseFromFaceId() }
                KeyButton(title: "0") { viewModel.append("0") }
                KeyButton(systemImage: "delete.left") { viewModel.removeLast() }
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)
        })
    }
}




#Preview {
    let navService = NavigationService()
    let localService = LocalizationService.shared
    return PassPhaseRegisterView()
        .environmentObject(navService)
        .environmentObject(localService)
}
