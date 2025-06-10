//
//  ReceiveStreamExecutor.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

public class ReceiveStreamExecutor {
    private let authentucationServicesClient: Ecliptix_Proto_Membership_AuthVerificationServices.ClientProtocol
    
    init(authentucationServicesClient: Ecliptix_Proto_Membership_AuthVerificationServices.ClientProtocol) {
        self.authentucationServicesClient = authentucationServicesClient
    }
    
    public func processRequestAsync(request: ServiceRequest, token: CancellationToken) async -> Result<RpcFlow, EcliptixProtocolFailure> {
        switch request.rcpServiceMethod {
            
        case .initiateVerification:
            return await initiateVerificationAsync(payload: request.payload, token: token)
        default:
            return .failure(.generic("Unsupported service method"))
        }
    }
    
    func initiateVerificationAsync(
        payload: Ecliptix_Proto_CipherPayload,
        token: CancellationToken
    ) async -> Result<RpcFlow, EcliptixProtocolFailure> {
        
        let throwingStream = AsyncThrowingStream<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>, Error> { continuation in
            Task {
                do {
                    try await authentucationServicesClient.initiateVerification(payload) { streamingResponse in
                        do {
                            for try await message in streamingResponse.messages {
                                continuation.yield(.success(message))
                            }
                            continuation.finish()
                        } catch {
                            let failure = Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>.failure(
                                error as? EcliptixProtocolFailure ?? .generic(error.localizedDescription)
                            )
                            continuation.yield(failure)
                            continuation.finish()
                        }
                        return ()
                    }
                } catch {
                    let failure = Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>.failure(
                        error as? EcliptixProtocolFailure ?? .generic(error.localizedDescription)
                    )
                    continuation.yield(failure)
                    continuation.finish()
                }
            }
        }
        
        let nonThrowingStream = AsyncStream<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>> { continuation in
            Task {
                do {
                    for try await element in throwingStream {
                        continuation.yield(element)
                    }
                    continuation.finish()
                } catch {
                    let failure = Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>.failure(
                        error as? EcliptixProtocolFailure ?? .generic(error.localizedDescription)
                    )
                    continuation.yield(failure)
                    continuation.finish()
                }
            }
        }
        
        let inboundStream = RpcFlow.InboundStream(stream: nonThrowingStream)
        return .success(inboundStream)
    }
}
