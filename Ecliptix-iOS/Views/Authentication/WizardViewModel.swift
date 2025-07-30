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

    init(
        connectionService: ApplicationInitializer
    ) {
        self.connectionService = connectionService
    }
    
    @MainActor
    func start() async {
        // Можна показати splash/loading
        step = .loading
        
        // 1. Ініціалізація (мережа, з'єднання тощо)
        _ = await connectionService.initializeAsync(defaultSystemSettings: DefaultSystemSettings())

        // 2. Логіка вибору: приклад
        step = .onboarding
    }
}
