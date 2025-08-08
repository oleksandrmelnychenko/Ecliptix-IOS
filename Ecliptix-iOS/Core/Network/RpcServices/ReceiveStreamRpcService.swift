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
    private let rpcMetaDataProvider: RpcMetaDataProviderProtocol
    
    private var serviceHandlers: [RpcServiceType: GrpcMethodDelegate] = [:]
    typealias GrpcMethodDelegate = (
        _ payload: Ecliptix_Proto_CipherPayload,
        _ token: CancellationToken
    ) async throws -> Result<RpcFlow, NetworkFailure>

    init(client: Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient, rpcMetaDataProvider: RpcMetaDataProviderProtocol) {
        self.client = client
        self.rpcMetaDataProvider = rpcMetaDataProvider
        
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
        cancellationToken: CancellationToken
    ) -> Result<RpcFlow, NetworkFailure> {
        let call: GRPCAsyncServerStreamingCall<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload> =
            client.makeInitiateVerificationCall(payload)
        
        let stream = AsyncThrowingStream<Result<Ecliptix_Proto_CipherPayload, NetworkFailure>, Error> { continuation in
            let reader = Task {
                do {
                    for try await item in call.responseStream {
                        if cancellationToken.cancelled || Task.isCancelled {
                            call.cancel()
                            break
                        }
                        continuation.yield(.success(item))
                    }
                    continuation.finish()
                } catch {
                    if cancellationToken.cancelled || Task.isCancelled {
                        continuation.finish()
                    } else {
                        let msg: String = (error as? GRPCStatus)?.message ?? error.localizedDescription
                        continuation.yield(.failure(.unexpectedError(msg, inner: error)))
                        continuation.finish()
                    }
                }
            }

            continuation.onTermination = { @Sendable _ in
                call.cancel()
                reader.cancel()
            }
        }

        return .success(
            RpcFlow.InboundStream(
                stream: stream,
                cancel: {
                    cancellationToken.cancel()
                    call.cancel()
                }
            )
        )
    }


    private func applyInterceptorsToClient(cancellationToken: CancellationToken) -> Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient {
        // Create a new interceptor factory with the cancellation token
        let authInterceptorFactory = AuthInterceptorFactory(
            rpcMetaDataProvider: rpcMetaDataProvider,
            cancellationToken: cancellationToken
        )

        let channel = GrpcClientFactory.createChannel()
        
        // Apply interceptors to the client
        let client = Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient(
            channel: channel,
            interceptors: authInterceptorFactory
        )

        return client
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
