//
//  PasscodeView.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 21.05.2025.
//

import SwiftUI

struct PassPhaseView: View {
    @StateObject private var viewModel: PassPhaseViewModel

    init(navigation: NavigationService) {
        _viewModel = StateObject(wrappedValue: PassPhaseViewModel(navigation: navigation))
    }

    private let columns = Array(repeating: GridItem(.flexible()), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            AuthViewHeader(
                viewTitle: Strings.PassPhase.title,
                viewDescription: Strings.PassPhase.description
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
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.horizontal)
            }

            // MARK: – Number pad
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(1...9, id: \.self) { number in
                    KeyButton(title: "\(number)") {
                        viewModel.append("\(number)")
                    }
                }

//                Color.clear.frame(height: 60)
                KeyButton(systemImage: "faceid") { viewModel.getPassPhaseFromFaceId() }
                KeyButton(title: "0") { viewModel.append("0") }
                KeyButton(systemImage: "delete.left") { viewModel.removeLast() }
            }
            .padding(.horizontal, 40)
            .padding(.top, 150)
            
            // MARK: – Submit
//            Button {
//                viewModel.submit()
//            } label: {
//                if viewModel.isLoading {
//                    ProgressView()
//                        .frame(maxWidth: .infinity).padding()
//                } else {
//                    Text(Strings.PassPhase.Buttons.submit)
//                        .frame(maxWidth: .infinity).padding()
//                }
//            }
//            .background(viewModel.isReady && !viewModel.isLoading ? Color.black : Color.gray)
//            .foregroundColor(.white)
//            .cornerRadius(10)
//            .disabled(!viewModel.isReady || viewModel.isLoading)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 100)
    }
}




#Preview {
    let navService = NavigationService()
    return PassPhaseView(navigation: navService)
        .environmentObject(navService)
}
