//
//  NetworkController.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import Foundation
import SwiftProtobuf

final class NetworkController {
    private let networkServiceManager: NetworkServiceManager
    
    private var connections: [UInt32: EcliptixConnectionContext] = [:]
    
    init(networkServiceManager: NetworkServiceManager) {
        self.networkServiceManager = networkServiceManager
    }
    
    func createEcliptixConnectionContext(connectId: UInt32, oneTimeKeyCount: UInt32, pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType) {
        do {
            let identityKeys = try EcliptixSystemIdentityKeys.create(oneTimeKeyCount: oneTimeKeyCount).unwrap()
            let protocolSystem = EcliptixProtocolSystem(ecliptixSystemIdentityKeys: identityKeys)
            let context = EcliptixConnectionContext(pubKeyExchangeType: pubKeyExchangeType, ecliptixProtocolSystem: protocolSystem)
            connections[connectId] = context
        } catch {
            debugPrint("Failed during creating Ecliptix system: \(error.localizedDescription)")
        }
    }
    
    func executeServiceAction(
        connectId: UInt32,
        serviceAction: RcpServiceAction,
        plainBuffer: Data,
        flowType: ServiceFlowType,
        onSuccessCallback: @escaping (Data) async -> Result<Unit, EcliptixProtocolFailure>,
        token: CancellationToken? = CancellationToken()
    ) async throws -> Result<Unit, EcliptixProtocolFailure> {
        guard let context = connections[connectId] else {
            return .failure(.generic("Connection not found"))
        }
        
        let protocolSystem = context.ecliptixProtocolSystem
        let pubKeyExchangeType = context.pubKeyExchangeType
        
        func buildRequest() throws -> ServiceRequest {
            let outboundPayload = try protocolSystem.produceOutboundMessage(
                connectId: connectId,
                exchangeType: pubKeyExchangeType,
                plainPayload: plainBuffer
            )
            return ServiceRequest.new(
                actionType: flowType,
                rcpServiceMethod: serviceAction,
                payload: outboundPayload,
                encryptedChunls: []
            )
        }
        
        do {
            return try await sendRequest(
                connectId: connectId,
                protocolSystem: protocolSystem,
                pubKeyExchangeType: pubKeyExchangeType,
                onSuccessCallback: onSuccessCallback,
                buildRequest()
            )
        } catch {
            switch SessionError.parse(from: error) {
            case .sessionExpired:
                if serviceAction == .registerAppDevice {
                    _ = await dataCenterPubKeyExchange(connectId: connectId)
                } else {
                    _ = await EstablishConnectionExecutor().reEstablishConnectionAsync()
                }

                do {
                    return try await sendRequest(
                        connectId: connectId,
                        protocolSystem: protocolSystem,
                        pubKeyExchangeType: pubKeyExchangeType,
                        onSuccessCallback: onSuccessCallback,
                        buildRequest()
                    )
                } catch {
                    return .failure(.generic("Reattempt after session expired failed", inner: error))
                }

            case .other(let inner):
                throw inner
            }
        }
    }
    
    private func sendRequest(
        connectId: UInt32,
        protocolSystem: EcliptixProtocolSystem,
        pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType,
        onSuccessCallback: @escaping (Data) async -> Result<Unit, EcliptixProtocolFailure>,
        _ request: ServiceRequest
    ) async throws -> Result<Unit, EcliptixProtocolFailure> {
        let invokeResult = try await networkServiceManager.invokeServiceRequestAsync(request: request, token: CancellationToken())

        if invokeResult.isErr {
            throw try invokeResult.unwrapErr()
        }

        let flow = try invokeResult.unwrap()

        switch flow {
            case let singleCall as RpcFlow.SingleCall:
                do {
                    let callResult = singleCall.result
                    if callResult.isErr {
                        return .failure(try callResult.unwrapErr())
                    }

                    let inboundPayload = try callResult.unwrap()
                    let decryptedData = try protocolSystem.processInboundMessage(sessionId: connectId, exchangeType: pubKeyExchangeType, cipherPayloadProto: inboundPayload)
                    let callbackOutcome = await onSuccessCallback(decryptedData)
                    if callbackOutcome.isErr {
                        return callbackOutcome
                    }
                } catch {
                    return .failure(.generic("Failed to process single call response", inner: error))
                }

            case let inboundStream as RpcFlow.InboundStream:
                do {
                    try await withTaskCancellationHandler(operation: {
                        for try await streamItem in inboundStream.stream {
                            if streamItem.isErr {
                                throw try streamItem.unwrapErr()
                            }

                            let streamPayload = try streamItem.unwrap()
                            let streamDecryptedData = try protocolSystem.processInboundMessage(sessionId: connectId, exchangeType: pubKeyExchangeType, cipherPayloadProto: streamPayload)

                            let streamCallbackOutcome = await onSuccessCallback(streamDecryptedData)
                            if streamCallbackOutcome.isErr {
                                debugPrint("Callback error: \(try streamCallbackOutcome.unwrapErr().message)")
                            }
                        }
                    }, onCancel: {
                        debugPrint("Stream cancelled for connectId: \(connectId)")
                    })
                } catch {
                    throw error
                }


            case is RpcFlow.OutboundSink, is RpcFlow.BidirectionalStream:
                return .failure(.generic("Unsupported stream type"))

            default:
                return .failure(.generic("Unsupported stream type"))
        }

        return .success(Unit.value)
    }

    
    public func dataCenterPubKeyExchange(connectId: UInt32) async -> Result<Unit, EcliptixProtocolFailure> {
        guard let context = connections[connectId] else {
            return .failure(.generic("Connection not found"))
        }
        
        do {
            let protocolSystem = context.ecliptixProtocolSystem
            let pubKeyExchangeType = context.pubKeyExchangeType
            
            let pubKeyExchange = try protocolSystem.beginDataCenterPubKeyExchange(connectId: connectId, exchangeType: pubKeyExchangeType)
            
            let action = PubKeyExchangeActionInvokable.new(jobType: .single, method: .dataCenterPubKeyExchange, pubKeyExchange: pubKeyExchange, callback: { peerPubKeyExchange in
                do {
                    try protocolSystem.completeDataCenterPubKeyExchange(connectId: connectId, exchangeType: pubKeyExchangeType, peerMessage: peerPubKeyExchange)
                } catch {
                    debugPrint("Failed to complete key exchange: \(error)")
                }
            })
            
            _ = await networkServiceManager.beginDataCenterPublicKeyExchange(action: action)
            
            return .success(.value)
        } catch {
            return .failure(.generic("Failed to begin key exchange", inner: error))
        }
    }
}
