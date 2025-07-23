//
//  ReceiveStreamExecutor.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import Foundation
import GRPC
import SwiftProtobuf

final class ReceiveStreamRpcService {
    private let client: Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient
    
    private var serviceHandlers: [RpcServiceType: GrpcMethodDelegate] = [:]
    typealias GrpcMethodDelegate = (
        _ payload: Ecliptix_Proto_CipherPayload,
        _ token: CancellationToken
    ) async throws -> Result<RpcFlow, NetworkFailure>

    init(client: Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient) {
        self.client = client
        
        self.serviceHandlers = [
            .initiateVerification: self.initiateVerificationAsync
        ]
    }

    func processRequestAsync(	
        request: ServiceRequest,
        token: CancellationToken
    ) async -> Result<RpcFlow, NetworkFailure> {
        guard let hadler = self.serviceHandlers[request.rcpServiceMethod] else {
            return .failure(.invalidRequestType("Unsupported service method"))
        }
        
        do {
            return try await hadler(request.payload, token)
        } catch {
            return .failure(.unexpectedError("Invocation failed", inner: error))
        }
    }

    private func initiateVerificationAsync(
        payload: Ecliptix_Proto_CipherPayload,
        token: CancellationToken
    ) -> Result<RpcFlow, NetworkFailure> {
        let stream = AsyncThrowingStream<Result<Ecliptix_Proto_CipherPayload, NetworkFailure>, Error> { continuation in
            Task {
                do {
                    let grpcStream = client.initiateVerification(payload)
                    for try await item in grpcStream {
                        continuation.yield(.success(item))
                    }
                    continuation.finish()
                } catch {
                    continuation.yield(.failure(.unexpectedError("Error during stream processing: \(error)", inner: error)))
                    continuation.finish()
                }
            }
        }

        return .success(RpcFlow.InboundStream(stream: stream))
    }
    
    private static func executeGrpcCallAsync(
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        _ grpcCallFactory: @escaping () async throws -> Ecliptix_Proto_CipherPayload
    ) async -> Result<Ecliptix_Proto_CipherPayload, NetworkFailure> {
        
        return await Result<Ecliptix_Proto_CipherPayload, NetworkFailure>.TryAsync {
            let response = try await GrpcResiliencePolicies.getSecrecyChannelRetryPolicy(networkEvents: networkEvents) {
                try await grpcCallFactory()
            }
            
            networkEvents.initiateChangeState(.new(.dataCenterDisconnected))
            
            return response
        } errorMapper: { error in
            systemEvents.publish(.new(.dataCenterShutdown))

            let message: String
            if let grpcStatus = error as? GRPCStatus {
                message = grpcStatus.message ?? grpcStatus.description
            } else {
                message = error.localizedDescription
            }

            return .dataCenterShutdown(message, inner: error)
        }
    }
}
