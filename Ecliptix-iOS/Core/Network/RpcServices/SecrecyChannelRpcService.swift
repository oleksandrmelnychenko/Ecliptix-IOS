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
    
    public func establishAppDeviceSecrecyChannel(request: Ecliptix_Proto_PubKeyExchange
    ) async throws -> Result<Ecliptix_Proto_PubKeyExchange, EcliptixProtocolFailure> {
        let options = CallOptions(timeLimit: .timeout(.seconds(20)))
        
        return await Self.executeGrpcCallAsync {
            try await self.appDeviceServiceActionsClient.establishAppDeviceSecrecyChannel(request, callOptions: options)
        }
    }
    
    public func restoreAppDeviceSecrecyChannelAsync(request: Ecliptix_Proto_RestoreSecrecyChannelRequest
    ) async throws -> Result<Ecliptix_Proto_RestoreSecrecyChannelResponse, EcliptixProtocolFailure> {
        let options = CallOptions(timeLimit: .timeout(.seconds(20)))
        
        return await Self.executeGrpcCallAsync {
            try await self.appDeviceServiceActionsClient.restoreAppDeviceSecrecyChannel(request, callOptions: options)
        }
    }
    
    private static func executeGrpcCallAsync<Response>(
        _ grpcCallFactory: @escaping () async throws -> Response
    ) async -> Result<Response, EcliptixProtocolFailure> {
        
        return await Result<Response, EcliptixProtocolFailure>.TryAsync {
            try await GrpcResiliencePolicies.getSecrecyChannelRetryPolicy {
                try await grpcCallFactory()
            }
        }
        .mapError { error in
            EcliptixProtocolFailure.generic(error.message, inner: error.innerError)
        }
    }
}
