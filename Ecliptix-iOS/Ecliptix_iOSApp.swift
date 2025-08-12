//
//  Ecliptix_iOSApp.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 09.06.2025.
//

import SwiftUI

@main
struct Ecliptix_iOSApp: App {
//    @State private var didInitialize = false
//    
//    @StateObject private var navigationService: NavigationService
//    @StateObject private var localizationService: LocalizationService
//    @StateObject private var wizardViewModel: WizardViewModel
//    
//    
//    init() {
//        ApplicationBootstrap.configure()
//        
//        let navService = try! ServiceLocator.shared.resolve(NavigationService.self)
//        let localService = try! ServiceLocator.shared.resolve(LocalizationService.self)
//        
//        _navigationService = StateObject(wrappedValue: navService)
//        _localizationService = StateObject(wrappedValue: localService)
//        
//        let initializer = ApplicationInitializer(
//            networkProvider: try! ServiceLocator.shared.resolve(NetworkProvider.self),
//            secureStorageProvider: try! ServiceLocator.shared.resolve(SecureStorageProviderProtocol.self),
//            localizationService: localService,
//            systemEvents: try! ServiceLocator.shared.resolve(SystemEventsProtocol.self))
//        
//        _wizardViewModel = StateObject(wrappedValue: WizardViewModel(
//            connectionService: initializer
//        ))
//    }
//    
//    var body: some Scene {
//        WindowGroup {
//            NavigationStack(path: $navigationService.path) {
//                WizardRootView()
//            }
//            .environmentObject(navigationService)
//            .environmentObject(localizationService)
//            .environmentObject(wizardViewModel)
//        }
//    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
