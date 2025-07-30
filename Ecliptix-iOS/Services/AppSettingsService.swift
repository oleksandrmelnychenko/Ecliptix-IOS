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

    public func getSettings() -> Result<Ecliptix_Proto_AppDevice_ApplicationInstanceSettings, InternalServiceApiFailure> {
        let getSettings = storage.tryGetByKey(key: self.key)
        
        guard getSettings.isOk, let data = try? getSettings.unwrap() else {
            return .failure(.secureStoreNotFound("Settings were not found."))
        }

        do {
            let settings = try Ecliptix_Proto_AppDevice_ApplicationInstanceSettings(serializedBytes: data)
            return .success(settings)
        } catch {
            return .failure(.deserialization("Failed during deserialization of settings data.", inner: error))
        }
    }

    public func setSettings(
        _ settings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings
    ) -> Result<Unit, InternalServiceApiFailure> {
            
        do {
            let data = try settings.serializedData()
            let result = storage.store(key: key, data: data)
            return result
        } catch {
            return .failure(.serialization("Failed during serialization of settings data.", inner: error))
        }
    }
    
    public func setMembership(_ membership: Ecliptix_Proto_Membership_Membership) -> Result<Unit, InternalServiceApiFailure> {
        return self.getSettings()
            .flatMap { settings in
                var newSettings = settings
                newSettings.membership = membership
                
                return self.setSettings(newSettings)
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
