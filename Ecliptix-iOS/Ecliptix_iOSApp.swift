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
    
    private let establishConnectionExecutor: EstablishConnectionExecutor
    
    init() {
        GrpcModule.configureServices()
        GrpcModule.configureGrpcClients()
                
        establishConnectionExecutor = EstablishConnectionExecutor()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationService.path) {
                WelcomeView(navigation: navigationService)
                    .environmentObject(navigationService)
                    .navigationDestination(for: AppRoute.self) { route in
                        ViewFactory.view(for: route, with: navigationService)
                    }
            }
            .task {
                guard !didInitialize else { return }
                didInitialize = true
                
                await establishConnectionExecutor.initializeApplicationAsync()
            }
        }
    }
}
