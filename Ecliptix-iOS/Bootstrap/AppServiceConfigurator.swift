//
//  AppServiceConfigurator.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 01.07.2025.
//

enum AppServiceConfigurator {
    static func registerCoreServices() {
        ServiceLocator.shared.register(AppSettings.self, service: AppSettings())
        ServiceLocator.shared.register(LocalizationService.self, service: LocalizationService.shared)
        ServiceLocator.shared.register(SecureStorageProviderProtocol.self, service: KeychainStorageProvider(ttlDays: 90))
        
        let metaProvider: RpcMetaDataProviderProtocol = RpcMetaDataProvider()
        ServiceLocator.shared.register(RpcMetaDataProviderProtocol.self, service: metaProvider)
    }
}
