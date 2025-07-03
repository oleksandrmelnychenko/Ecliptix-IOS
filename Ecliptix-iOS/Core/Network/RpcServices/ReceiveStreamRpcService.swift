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

    init(client: Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient) {
        self.client = client
    }

    func processRequestAsync(	
        request: ServiceRequest
    ) -> Result<RpcFlow, EcliptixProtocolFailure> {
        switch request.rcpServiceMethod {
        case .initiateVerification:
            return initiateVerificationAsync(payload: request.payload)
        default:
            return .failure(.generic("Unsupported service method"))
        }
    }

    private func initiateVerificationAsync(
        payload: Ecliptix_Proto_CipherPayload
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
