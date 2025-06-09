//
//  KeyExchangeExecutor.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import SwiftProtobuf
import Foundation

public final class KeyExchangeExecutor {
    private let appDeviceServiceActionsClient: Ecliptix_Proto_AppDevice_AppDeviceServiceActions.ClientProtocol
    
    init(appDeviceServiceActionsClient: Ecliptix_Proto_AppDevice_AppDeviceServiceActions.ClientProtocol) {
        self.appDeviceServiceActionsClient = appDeviceServiceActionsClient
    }
    
    public func beginDataCenterPublicKeyExchange(request: Ecliptix_Proto_PubKeyExchange) async -> Result<Ecliptix_Proto_PubKeyExchange, EcliptixProtocolFailure> {
        return await Result<Ecliptix_Proto_PubKeyExchange, EcliptixProtocolFailure>.TryAsync {
            let response = try await self.appDeviceServiceActionsClient.establishAppDeviceEphemeralConnect(request)
            return response
        }.mapError { error in
            .generic(error.message, inner: error.innerError)
        }
    }
}
