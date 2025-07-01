//
//  AppServiceConfigurator.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 01.07.2025.
//

enum AppServiceConfigurator {
    static func registerCoreServices() {
        ServiceLocator.shared.register(AppSettings.self, service: AppSettings())
        ServiceLocator.shared.register(AppInstanceInfo.self, service: AppInstanceInfo())
        ServiceLocator.shared.register(LocalizationService.self, service: LocalizationService.shared)
    }
}
