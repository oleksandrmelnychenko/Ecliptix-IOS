//
//  RequestExecutor.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 05.08.2025.
//

import Foundation

final class RequestExecutor {
    private let rpcServiceManager: RpcServiceManager
    
    init(rpcServiceManager: RpcServiceManager) {
        self.rpcServiceManager = rpcServiceManager
    }
    
    func executeServiceAction(
        connectId: UInt32,
        serviceType: RpcServiceType,
        plainBuffer: Data,
        flowType: ServiceFlowType,
        token: CancellationToken? = CancellationToken(),
        onRetry: @escaping (_ settings: inout Ecliptix_Proto_AppDevice_ApplicationInstanceSettings, _ serviceType: RpcServiceType) async -> Void
    ) async -> Result<Data, NetworkFailure> {
        let getSettingsResult = AppSettingsService.shared.getSettings()

        guard case var .success(settings) = getSettingsResult else {
            return .failure(.unexpectedError("Missing app settings"))
        }
        
        return await RetryExecutor.executeResult(
            maxRetryCount: nil,
            retryCondition: { result in
                guard result.isErr else { return false }
                
                let failure: NetworkFailure
                do {
                    failure = try result.unwrapErr()
                } catch {
                    return false
                }

                let errorToParse = failure.innerError ?? failure
                if case .sessionExpired = SessionError.parse(from: errorToParse) {
                    return true
                } else {
                    return false
                }
            },
            onRetry: { _, _ in
                await onRetry(&settings, serviceType)
            })
            {
                guard let protocolSystem = ConnectionStore.shared.get(for: connectId) else {
                    return .failure(.invalidRequestType("Connection not found"))
                }

                do {
                    let requestResult = self.buildRequest(
                        protocolSystem: protocolSystem,
                        plainBuffer: plainBuffer,
                        flowType: flowType,
                        serviceType: serviceType
                    )

                    guard requestResult.isOk else {
                        return .failure(try requestResult.unwrapErr())
                    }

                    let request = try requestResult.unwrap()
                    return await self.sendRequest(
                        connectId: connectId,
                        protocolSystem: protocolSystem,
                        request
                    )
                } catch {
                    return .failure(.unexpectedError("Unhandled error during execution of request.", inner: error))
                }
            }
    }
    
    func executeStreamServiceAction(
        connectId: UInt32,
        serviceType: RpcServiceType,
        plainBuffer: Data,
        token: CancellationToken? = CancellationToken()
    ) async -> Result<AsyncThrowingStream<Result<Data, NetworkFailure>, Error>, NetworkFailure> {
        guard let protocolSystem = ConnectionStore.shared.get(for: connectId) else {
            return .failure(.invalidRequestType("Connection not found"))
        }

        do {
            let requestResult = self.buildRequest(
                protocolSystem: protocolSystem,
                plainBuffer: plainBuffer,
                flowType: .receiveStream,
                serviceType: serviceType
            )

            guard requestResult.isOk else {
                return .failure(try requestResult.unwrapErr())
            }

            let request = try requestResult.unwrap()
            let result = await rpcServiceManager.invokeServiceRequestAsync(
                request: request,
                token: token ?? CancellationToken()
            )

            guard let inboundStream = try result.unwrap() as? RpcFlow.InboundStream else {
                return .failure(.invalidRequestType("Expected inbound stream"))
            }

            let decryptedStream = AsyncThrowingStream<Result<Data, NetworkFailure>, Error> { continuation in
                Task {
                    do {
                        for try await item in inboundStream.stream {
                            switch item {
                            case .failure(let failure):
                                continuation.yield(.failure(failure))
                            case .success(let payload):
                                do {
                                    let decryptedResult = try protocolSystem.processInboundMessage(cipherPayloadProto: payload)
                                    switch decryptedResult {
                                    case .success(let decryptedData):
                                        continuation.yield(.success(decryptedData))
                                    case .failure(let decryptionError):
                                        continuation.yield(with: .failure(decryptionError))
                                    }
                                } catch {
                                    continuation.yield(.failure(.unexpectedError("Failed to decrypt payload", inner: error)))
                                }
                            }
                        }
                        continuation.finish()
                    } catch {
                        continuation.yield(.failure(.unexpectedError("Stream error", inner: error)))
                        continuation.finish()
                    }
                }
            }

            return .success(decryptedStream)

        } catch {
            return .failure(.unexpectedError("Unhandled stream error", inner: error))
        }
    }

    
    private func buildRequest(
        protocolSystem: EcliptixProtocolSystem,
        plainBuffer: Data,
        flowType: ServiceFlowType,
        serviceType: RpcServiceType
    ) -> Result<ServiceRequest, NetworkFailure> {
        do {
            let outboundPayload = try protocolSystem.produceOutboundMessage(plainPayload: plainBuffer)
            
            let request = ServiceRequest.new(
                actionType: flowType,
                rcpServiceMethod: serviceType,
                payload: try outboundPayload.unwrap(),
                encryptedChunls: []
            )
            
            return .success(request)
        } catch {
            return .failure(.unexpectedError("Failed to build the request", inner: error))
        }
    }
    
    private func sendRequest(
        connectId: UInt32,
        protocolSystem: EcliptixProtocolSystem,
        _ request: ServiceRequest
    ) async -> Result<Data, NetworkFailure> {
        do {
            let invokeResult = await rpcServiceManager.invokeServiceRequestAsync(request: request, token: CancellationToken())

            if invokeResult.isErr {
                return .failure(try invokeResult.unwrapErr())
            }

            let flow = try invokeResult.unwrap()

            switch flow {
                case let singleCall as RpcFlow.SingleCall:
                    do {
                        let callResult = await singleCall.result()
                        if callResult.isErr {
                            return .failure(try callResult.unwrapErr())
                        }

                        let inboundPayload = try callResult.unwrap()
                        let decryptedData = try protocolSystem.processInboundMessage(cipherPayloadProto: inboundPayload)
                        return .success(try decryptedData.unwrap())
                    } catch {
                        return .failure(.unexpectedError("Failed to process single call response", inner: error))
                    }
                case is RpcFlow.OutboundSink, is RpcFlow.BidirectionalStream:
                    return .failure(.invalidRequestType("Unsupported stream type"))

                default:
                    return .failure(.invalidRequestType("Unsupported stream type"))
            }
            
            return .success(Data())
        } catch {
            return .failure(.unexpectedError("Unhandled error", inner: error))
        }
    }
    
    func sendRequestStream(
        connectId: UInt32,
        protocolSystem: EcliptixProtocolSystem,
        request: ServiceRequest
    ) async -> Result<AsyncThrowingStream<Result<Data, NetworkFailure>, Error>, NetworkFailure> {
        do {
            let invokeResult = await rpcServiceManager.invokeServiceRequestAsync(
                request: request,
                token: CancellationToken()
            )
            
            if invokeResult.isErr {
                return .failure(try invokeResult.unwrapErr())
            }
            
            let flow = try invokeResult.unwrap()
            guard let stream = flow as? RpcFlow.InboundStream else {
                return .failure(.invalidRequestType("Expected InboundStream, got \(type(of: flow))"))
            }

            let transformedStream = AsyncThrowingStream<Result<Data, NetworkFailure>, Error> { continuation in
                Task {
                    do {
                        for try await item in stream.stream {
                            switch item {
                            case .success(let payload):
                                let decrypted = try protocolSystem.processInboundMessage(cipherPayloadProto: payload)
                                continuation.yield(.success(try decrypted.unwrap()))
                            case .failure(let failure):
                                continuation.yield(.failure(failure))
                            }
                        }
                        continuation.finish()
                    } catch {
                        continuation.yield(.failure(.unexpectedError("Stream error", inner: error)))
                        continuation.finish()
                    }
                }
            }
            
            return .success(transformedStream)
        } catch {
            return .failure(.unexpectedError("Failed to handle stream", inner: error))
        }
    }
}
