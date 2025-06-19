//
//  KeyExchangeExecutor.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import SwiftProtobuf
import Foundation
import GRPC

internal final class KeyExchangeExecutor {
    private let appDeviceServiceActionsClient: Ecliptix_Proto_AppDevice_AppDeviceServiceActionsAsyncClient
    
    init(appDeviceServiceActionsClient: Ecliptix_Proto_AppDevice_AppDeviceServiceActionsAsyncClient) {
        self.appDeviceServiceActionsClient = appDeviceServiceActionsClient
    }
    
    public func beginDataCenterPublicKeyExchange(request: Ecliptix_Proto_PubKeyExchange) async -> Result<Ecliptix_Proto_PubKeyExchange, EcliptixProtocolFailure> {
        return try! await RetryExecutor.execute(retryCondition: RetryCondition.grpcUnavailableOnly,
            {
                try await self.appDeviceServiceActionsClient.establishAppDeviceEphemeralConnect(request)
            }
        )
    }
}
