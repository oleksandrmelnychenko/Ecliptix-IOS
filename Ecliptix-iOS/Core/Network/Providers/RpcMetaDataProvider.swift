//
//  ClientStateProvider.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 02.07.2025.
//

import Foundation

final class RpcMetaDataProvider: RpcMetaDataProviderProtocol, @unchecked Sendable {
    private var _appInstanceId: UUID
    private var _deviceId: UUID
    private let queue = DispatchQueue(label: "com.ecliptix.rpcMetaDataProvider.queue", attributes: .concurrent)

    init(appInstanceId: UUID = UUID(), deviceId: UUID = UUID()) {
        self._appInstanceId = appInstanceId
        self._deviceId = deviceId
    }

    func getAppInstanceId() -> UUID {
        queue.sync { _appInstanceId }
    }

    func getDeviceId() -> UUID {
        queue.sync { _deviceId }
    }

    func setAppInfo(appInstanceId: UUID, deviceId: UUID) {
        queue.async(flags: .barrier) {
            self._appInstanceId = appInstanceId
            self._deviceId = deviceId
        }
    }

    func clear() {
        queue.async(flags: .barrier) {
            self._appInstanceId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
            self._deviceId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        }
    }
}
