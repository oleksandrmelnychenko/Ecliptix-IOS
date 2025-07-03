//
//  ClientStateProvider.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 02.07.2025.
//

import Foundation

protocol RpcMetaDataProviderProtocol: Sendable {
    func getAppInstanceId() -> UUID
    func getDeviceId() -> UUID

    func setAppInfo(appInstanceId: UUID, deviceId: UUID)
    func clear()
}

