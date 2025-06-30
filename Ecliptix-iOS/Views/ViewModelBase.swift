//
//  ViewModelBase.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.06.2025.
//

import Foundation

enum ViewModelBase {
    static func computeConnectId(pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType) -> UInt32 {
        let appInstanceInfo = ServiceLocator.shared.resolve(AppInstanceInfo.self)
        
        let connectId = Utilities.computeUniqueConnectId(
            appInstanceId: appInstanceInfo.appInstanceId,
            appDeviceId: appInstanceInfo.deviceId,
            contextType: pubKeyExchangeType)
        
        return connectId
    }
    
    static func serverPublicKey() async -> Data {
        let appInstanceInfo = ServiceLocator.shared.resolve(AppInstanceInfo.self)
        return await appInstanceInfo.serverPublicKey
    }
    
    static func systemDeviceIdentifier() async -> UUID? {
        let appInstanceInfo = ServiceLocator.shared.resolve(AppInstanceInfo.self)
        return await appInstanceInfo.systemDeviceIdentifier
    }
}
