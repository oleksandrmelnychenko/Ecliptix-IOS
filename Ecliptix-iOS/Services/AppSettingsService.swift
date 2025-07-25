//
//  AppSettingsService.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 25.07.2025.
//

import Foundation

final class AppSettingsService {
    static var shared: AppSettingsService!

    private let storage: SecureStorageProviderProtocol
    private let key: String = "ApplicationInstanceSettings"

    init(storage: SecureStorageProviderProtocol) {
        self.storage = storage
    }

    public func getSettings() -> Ecliptix_Proto_AppDevice_ApplicationInstanceSettings? {
        let getSettings = storage.tryGetByKey(key: self.key)
        if getSettings.isErr {
            return nil
        }
        
        guard let data = try? getSettings.unwrap() else { return nil }
        
        return try? Ecliptix_Proto_AppDevice_ApplicationInstanceSettings(serializedBytes: data)
    }

    public func setSettings(
        _ settings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings
    ) {
            
        if let data = try? settings.serializedData() {
            let storedNewSettingsResult = storage.store(key: key, data: data)
            
            guard storedNewSettingsResult.isOk else {
                return
            }
        }
    }
    
    static func computeUniqueConnectId(
        settings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings,
        pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType
    ) -> UInt32 {
        return Helpers.computeUniqueConnectId(
            appInstanceId: settings.appInstanceID,
            appDeviceId: settings.deviceID,
            contextType: pubKeyExchangeType)
    }
}
