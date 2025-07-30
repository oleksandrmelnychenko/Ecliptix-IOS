//
//  ViewModelBase.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.06.2025.
//

import Foundation

enum ViewModelBase {
    static func computeConnectId(
        pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType
    ) -> Result<UInt32, InternalServiceApiFailure> {
        AppSettingsService.shared.getSettings()
            .flatMap { settings in
                let connectId = Helpers.computeUniqueConnectId(
                    appInstanceId: settings.appInstanceID,
                    appDeviceId: settings.deviceID,
                    contextType: pubKeyExchangeType
                )
                
                return .success(connectId)
            }
    }

    static func serverPublicKey() -> Result<Data, InternalServiceApiFailure> {
        AppSettingsService.shared.getSettings()
            .map { settings in settings.serverPublicKey }
    }

    static func systemDeviceIdentifier() -> Result<String, InternalServiceApiFailure> {
        AppSettingsService.shared.getSettings()
            .map { settings in settings.systemDeviceIdentifier }
    }
    
    static func membership() -> Result<Ecliptix_Proto_Membership_Membership, InternalServiceApiFailure> {
        AppSettingsService.shared.getSettings()
            .map { settings in settings.membership }
    }
}
