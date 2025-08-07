//
//  WizardViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.07.2025.
//

import Foundation
import Combine

final class WizardViewModel: ObservableObject {
    @Published var step: AuthenticationUserState = .notInitialized
    
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
                
        let initializedResult = await connectionService.initializeAsync(defaultSystemSettings: DefaultSystemSettings())
        
        _ = await connectionService.retriveUserState().map { authUserState in
            step = .notInitialized
        }
    }
}
