//
//  ViewModelBase.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.06.2025.
//

import Foundation

enum ViewModelBase {
    static func computeConnectId(
        networkProvider: NetworkProvider,
        pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType
    ) -> Result<UInt32, InternalServiceApiFailure> {
        guard let settings = AppSettingsService.shared.getSettings() else {
            return .failure(.dependencyResolution("Missing application instance settings. Cannot compute connectId without valid settings."))
        }
        
        let connectId = Helpers.computeUniqueConnectId(
            appInstanceId: settings.appInstanceID,
            appDeviceId: settings.deviceID,
            contextType: pubKeyExchangeType
        )
        
        return .success(connectId)
    }

    static func serverPublicKey(networkProvider: NetworkProvider) -> Result<Data, InternalServiceApiFailure> {
        guard let settings = AppSettingsService.shared.getSettings() else {
            return .failure(.dependencyResolution("Missing application instance settings. Cannot compute connectId without valid settings."))
        }
        
        return .success(settings.serverPublicKey)
    }

    static func systemDeviceIdentifier(networkProvider: NetworkProvider) -> Result<String, InternalServiceApiFailure> {
        guard let settings = AppSettingsService.shared.getSettings() else {
            return .failure(.dependencyResolution("Missing application instance settings. Cannot compute connectId without valid settings."))
        }
        
        return .success(settings.systemDeviceIdentifier)
    }
}
