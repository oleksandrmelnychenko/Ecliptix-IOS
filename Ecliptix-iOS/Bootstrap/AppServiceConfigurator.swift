//
//  AppServiceConfigurator.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 01.07.2025.
//

enum AppServiceConfigurator {
    @MainActor static func registerCoreServices() {
        ServiceLocator.shared.register(DefaultSystemSettings.self, service: DefaultSystemSettings())
        ServiceLocator.shared.register(SecureStorageProviderProtocol.self, service: KeychainStorageProvider(ttlDays: 90))
        
        ServiceLocator.shared.register(NavigationService.self, service: NavigationService())
        ServiceLocator.shared.register(LocalizationService.self, service: LocalizationService.shared)
        
        let metaProvider: RpcMetaDataProviderProtocol = RpcMetaDataProvider()
        ServiceLocator.shared.register(RpcMetaDataProviderProtocol.self, service: metaProvider)
        
        Logger.configure(
            minimumLevel: .debug,
            maxFileSize: 10_000_000,
            retainedFileCountLimit: 7)
        Logger.overrides = [
            "Networking": .info,
            "UI": .error
        ]
        
        let aggregator: EventAggregator = EventAggregator()
        ServiceLocator.shared.register(EventAggregatorProtocol.self, service: aggregator)
        ServiceLocator.shared.register(NetworkEventsProtocol.self, service: NetworkEvents(aggregator: aggregator))
        ServiceLocator.shared.register(SystemEventsProtocol.self, service: SystemEvents(aggregator: aggregator))
    }
}
