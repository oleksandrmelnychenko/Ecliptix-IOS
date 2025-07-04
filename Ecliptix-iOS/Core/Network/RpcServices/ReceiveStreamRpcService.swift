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
    typealias GrpcMethodDelegate = (_ payload: Ecliptix_Proto_CipherPayload, _ token: CancellationToken) async throws -> Result<RpcFlow, EcliptixProtocolFailure>

    init(client: Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient) {
        self.client = client
        
        self.serviceHandlers = [
            .initiateVerification: self.initiateVerificationAsync
        ]
    }

    func processRequestAsync(	
        request: ServiceRequest,
        token: CancellationToken
    ) async -> Result<RpcFlow, EcliptixProtocolFailure> {
        guard let hadler = self.serviceHandlers[request.rcpServiceMethod] else {
            return .failure(.invalidInput("Unsupported handler"))
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
    ) -> Result<RpcFlow, EcliptixProtocolFailure> {
        let stream = AsyncThrowingStream<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>, Error> { continuation in
            Task {
                do {
                    let grpcStream = client.initiateVerification(payload)
                    for try await item in grpcStream {
                        continuation.yield(.success(item))
                    }
                    continuation.finish()
                } catch {
                    continuation.yield(.failure(.generic("Error during stream processing: \(error)", inner: error)))
                    continuation.finish()
                }
            }
        }

        return .success(RpcFlow.InboundStream(stream: stream))
    }
}
