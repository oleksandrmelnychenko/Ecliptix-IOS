//
//  WizardRootView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.07.2025.
//

import SwiftUI

struct WizardRootView: View {
    @EnvironmentObject var wizardViewModel: WizardViewModel

    var body: some View {
        Group {
            switch wizardViewModel.step {
            case .loading:
                ProgressView("Loading...")
            case .onboarding:
                WelcomeView()
            }
        }
        .task {
            await wizardViewModel.start()
        }
    }
}
