//
//  WizardRootView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.07.2025.
//

import SwiftUI

struct WizardRootView: View {
    @EnvironmentObject var wizardViewModel: WizardViewModel
    @EnvironmentObject var navigationService: NavigationService
    @EnvironmentObject var localizationService: LocalizationService

    var body: some View {
        Group {
            switch wizardViewModel.step {
            case .loading:
                ProgressView("Loading...")
            case .onboarding:
                NavigationStack(path: $navigationService.path) {
                    WelcomeView()
                        .navigationDestination(for: AppRoute.self) { route in
                            ViewFactory.view(for: route)
                        }
                }
            }
        }
        .task {
            await wizardViewModel.start()
        }
    }
}
