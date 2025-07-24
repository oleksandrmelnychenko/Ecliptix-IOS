//
//  ViewModelBase.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.06.2025.
//

import Foundation

enum ViewModelBase {
    static func computeConnectId(pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType) -> Result<UInt32, InternalServiceApiFailure> {
        self.getSettings()
            .map { appInstanceInfo in
                Helpers.computeUniqueConnectId(
                    appInstanceId: appInstanceInfo.appInstanceID,
                    appDeviceId: appInstanceInfo.deviceID,
                    contextType: pubKeyExchangeType
                )
            }
    }

    static func serverPublicKey() -> Result<Data, InternalServiceApiFailure> {
        self.getSettings()
            .map { appInstanceInfo in
                appInstanceInfo.serverPublicKey
            }
    }

    static func systemDeviceIdentifier() -> Result<String, InternalServiceApiFailure> {
        self.getSettings()
            .map { appInstanceInfo in
                appInstanceInfo.systemDeviceIdentifier
            }
    }
    
    private static func getSettings() -> Result<Ecliptix_Proto_AppDevice_ApplicationInstanceSettings, InternalServiceApiFailure> {
        let settingsKey = "ApplicationInstanceSettings"
        
        let secureStorageProvider: SecureStorageProviderProtocol
        
        do {
            secureStorageProvider = try ServiceLocator.shared.resolve(SecureStorageProviderProtocol.self)
        } catch {
            return .failure(.dependencyResolution("Failed to resolve secure storage", inner: error))
        }
        
        return secureStorageProvider.tryGetByKey(key: settingsKey)
            .flatMap { maybeSettingsData in
                guard let data = maybeSettingsData else {
                    return .failure(.secureStoreKeyNotFound("No settings in storage for key '\(settingsKey)'"))
                }

                do {
                    let existingSettings = try Ecliptix_Proto_AppDevice_ApplicationInstanceSettings(serializedBytes: data)
                    return .success(existingSettings)
                } catch {
                    return .failure(.deserialization("Failed to deserialize settings: \(error.localizedDescription)"))
                }
            }
    }
}
