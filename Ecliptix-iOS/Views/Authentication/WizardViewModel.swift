//
//  WizardViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.07.2025.
//

import Foundation
import Combine

enum WizardStep {
    case onboarding
    case loading
}

final class WizardViewModel: ObservableObject {
    @Published var step: WizardStep = .loading
    
    private let connectionService: ApplicationInitializer
    private var hasStarted = false

    init(
        connectionService: ApplicationInitializer
    ) {
        self.connectionService = connectionService
    }
    
    @MainActor
    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        
        step = .onboarding
        
        _ = await connectionService.initializeAsync(defaultSystemSettings: DefaultSystemSettings())
    }
}
