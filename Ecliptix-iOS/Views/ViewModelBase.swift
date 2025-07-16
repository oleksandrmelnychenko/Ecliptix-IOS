//
//  ViewModelBase.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.06.2025.
//

import Foundation

enum ViewModelBase {
    static func computeConnectId(pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType) -> UInt32 {
        switch getSettings() {
        case .success(let appInstanceInfo):
            return Helpers.computeUniqueConnectId(
                appInstanceId: appInstanceInfo.appInstanceID,
                appDeviceId: appInstanceInfo.deviceID,
                contextType: pubKeyExchangeType
            )
        case .failure:
            return 0 
        }
    }

    static func serverPublicKey() -> Data {
        switch getSettings() {
        case .success(let appInstanceInfo):
            return appInstanceInfo.serverPublicKey
        case .failure:
            return Data()
        }
    }

    static func systemDeviceIdentifier() -> String? {
        switch getSettings() {
        case .success(let appInstanceInfo):
            return appInstanceInfo.systemDeviceIdentifier
        case .failure:
            return nil
        }
    }
    
    private static func getSettings() -> Result<Ecliptix_Proto_AppDevice_ApplicationInstanceSettings, InternalServiceApiFailure> {
        let settingsKey = "ApplicationInstanceSettings"
        
        do {
            let secureStorageProvider = ServiceLocator.shared.resolve(SecureStorageProviderProtocol.self)
            
            let getResult = secureStorageProvider.tryGetByKey(key: settingsKey)
            guard getResult.isOk else {
                return .failure(try getResult.unwrapErr())
            }
            
            let maybeSettingsData = try getResult.unwrap()
            
            if let data = maybeSettingsData {
                let existingSettings = try Ecliptix_Proto_AppDevice_ApplicationInstanceSettings(serializedBytes: data)
                return .success(existingSettings)
            }
            
            return .failure(.secureStoreKeyNotFound("No settings in storage for key '\(settingsKey)'"))
        }
        catch {
            return .failure(.secureStoreUnknown("An unexpected error occurred while retrieving or storing instance settings", inner: error))
        }
    }
}
