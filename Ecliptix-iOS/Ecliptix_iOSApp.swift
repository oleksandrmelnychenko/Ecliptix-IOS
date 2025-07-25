//
//  Ecliptix_iOSApp.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 09.06.2025.
//

import SwiftUI

@main
struct Ecliptix_iOSApp: App {
    @State private var didInitialize = false
    
    @StateObject private var navigationService = NavigationService()
    @StateObject private var localizationService = LocalizationService.shared
    
    private let establishConnectionExecutor: ApplicationInitializer
    
    init() {
        ApplicationBootstrap.configure()
                
        establishConnectionExecutor = ApplicationInitializer(
            networkProvider: try! ServiceLocator.shared.resolve(NetworkProvider.self),
            secureStorageProvider: try! ServiceLocator.shared.resolve(SecureStorageProviderProtocol.self),
            systemEvents: try! ServiceLocator.shared.resolve(SystemEventsProtocol.self))
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationService.path) {
                WelcomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        ViewFactory.view(for: route)
                    }
            }
            .environmentObject(navigationService)
            .environmentObject(localizationService)
            .task {
                guard !didInitialize else { return }
                didInitialize = true
                
                _ = await establishConnectionExecutor.initializeAsync()
            }
        }
    }
}
