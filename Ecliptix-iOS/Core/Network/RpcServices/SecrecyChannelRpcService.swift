//
//  KeyExchangeExecutor.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import SwiftProtobuf
import Foundation
import GRPC

internal final class SecrecyChannelRpcService {
    private let appDeviceServiceActionsClient: Ecliptix_Proto_AppDevice_AppDeviceServiceActionsAsyncClient
    
    init(appDeviceServiceActionsClient: Ecliptix_Proto_AppDevice_AppDeviceServiceActionsAsyncClient) {
        self.appDeviceServiceActionsClient = appDeviceServiceActionsClient
    }
    
    public func establishAppDeviceSecrecyChannel(request: Ecliptix_Proto_PubKeyExchange) async throws -> Result<Ecliptix_Proto_PubKeyExchange, EcliptixProtocolFailure> {
        return await Self.executeGrpcCallAsync {
            try await self.appDeviceServiceActionsClient.establishAppDeviceSecrecyChannel(request)
        }
    }
    
    public func restoreAppDeviceSecrecyChannelAsync(request: Ecliptix_Proto_RestoreSecrecyChannelRequest) async throws -> Result<Ecliptix_Proto_RestoreSecrecyChannelResponse, EcliptixProtocolFailure> {
        
        return await Self.executeGrpcCallAsync {
            try await self.appDeviceServiceActionsClient.restoreAppDeviceSecrecyChannel(request)
        }
    }
    
    private static func executeGrpcCallAsync<Response>(
        _ grpcCallFactory: @escaping () async throws -> Response
    ) async -> Result<Response, EcliptixProtocolFailure> {
        
        let conditions: [(Error) -> Bool] = [
            RetryCondition.grpcUnavailableOnly,
            RetryCondition.grpcDeadlineExceededOnly,
            RetryCondition.grpcResourceExhaustedOnly
        ]
        
        return await Result<Response, EcliptixProtocolFailure>.TryAsync {
            try await RetryExecutor.execute(retryConditions: conditions) {
                try await grpcCallFactory()
            }.unwrap()
        }.mapError { error in
            EcliptixProtocolFailure.generic(error.message, inner: error.innerError)
        }
    }
}
