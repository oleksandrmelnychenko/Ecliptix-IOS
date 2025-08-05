//
//  DeviceRegistrar.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 05.08.2025.
//

final class DeviceRegistrar {
    private let requestExecutor: RequestExecutor
    private let secureStorageProvider: SecureStorageProviderProtocol

    init(
        requestExecutor: RequestExecutor,
        secureStorageProvider: SecureStorageProviderProtocol
    ) {
        self.requestExecutor = requestExecutor
        self.secureStorageProvider = secureStorageProvider
    }
}
