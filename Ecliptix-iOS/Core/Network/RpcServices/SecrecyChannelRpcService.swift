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
    
    /// Establishes a secrecy channel with the app device service.
    public func establishAppDeviceSecrecyChannel(
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        request: Ecliptix_Proto_PubKeyExchange
    ) async throws -> Result<Ecliptix_Proto_PubKeyExchange, NetworkFailure> {
        await Self.executeGrpcCallAsync(networkEvents: networkEvents, systemEvents: systemEvents) {
            try await self.appDeviceServiceActionsClient.establishAppDeviceSecrecyChannel(request)
        }
    }
    
    /// Restores a secrecy channel with the app device service.
    public func restoreAppDeviceSecrecyChannelAsync(
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        request: Ecliptix_Proto_RestoreSecrecyChannelRequest
    ) async throws -> Result<Ecliptix_Proto_RestoreSecrecyChannelResponse, NetworkFailure> {
        await Self.executeGrpcCallAsync(networkEvents: networkEvents, systemEvents: systemEvents) {
            try await self.appDeviceServiceActionsClient.restoreAppDeviceSecrecyChannel(request)
        }
    }
    
    private static func executeGrpcCallAsync<TResponse>(
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        _ grpcCallFactory: @escaping () async throws -> TResponse
    ) async -> Result<TResponse, NetworkFailure> {
        
        return await Result<TResponse, NetworkFailure>.TryAsync {
            let response = try await GrpcResiliencePolicies.getSecrecyChannelRetryPolicy(networkEvents: networkEvents) {
                try await grpcCallFactory()
            }
            
            networkEvents.initiateChangeState(.new(.dataCenterConnected))
            
            return response
        } errorMapper: { error in
            systemEvents.publish(.new(.dataCenterShutdown))
            
            return .dataCenterShutdown(error.localizedDescription)
        }
    }
}
