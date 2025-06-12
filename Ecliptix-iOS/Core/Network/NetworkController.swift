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
            
        }
    }
    
    func executeServiceAction(connectId: UInt32, serviceAction: RcpServiceAction, plainBuffer: Data, flowType: ServiceFlowType, onSuccessCallback: @escaping (Data) async -> Result<Unit, EcliptixProtocolFailure>, token: CancellationToken? = CancellationToken()
    ) async -> Result<Unit, EcliptixProtocolFailure> {
        guard let context = connections[connectId] else {
            return .failure(.generic("Connection not found"))
        }
        
        do {
            let protocolSystem = context.ecliptixProtocolSystem
            let pubKeyExchangeType = context.pubKeyExchangeType
            
            let outboundPayload = try protocolSystem.produceOutboundMessage(connectId: connectId, exchangeType: pubKeyExchangeType, plainPayload: plainBuffer)
            
            let request = ServiceRequest.new(actionType: flowType, rcpServiceMethod: serviceAction, payload: outboundPayload, encryptedChunls: [])
            let invokeResult = await networkServiceManager.invokeServiceRequestAsync(request: request, token: token!)
            
            if invokeResult.isErr {
                return .failure(try invokeResult.unwrapErr())
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
                                    print("Stream error: \(try streamItem.unwrapErr().message)")
                                    continue
                                }
                                
                                let streamPayload = try streamItem.unwrap()
                                let streamDecryptedData = try protocolSystem.processInboundMessage(sessionId: connectId, exchangeType: pubKeyExchangeType, cipherPayloadProto: streamPayload)
                                
                                let streamCallbackOutcome = await onSuccessCallback(streamDecryptedData)
                                if streamCallbackOutcome.isErr {
                                    print("Callback error: \(try streamCallbackOutcome.unwrapErr().message)")
                                }
                            }
                        }, onCancel: {
                            print("Stream cancelled for connectId: \(connectId)")
                        })
                    } catch {
                        return .failure(.generic("Failed during inbound stream processing", inner: error))
                    }
                    
                    
                case is RpcFlow.OutboundSink, is RpcFlow.BidirectionalStream:
                    return .failure(.generic("Unsupported stream type"))
                
                default:
                    return .failure(.generic("Unsupported stream type"))
            }
            
            return .success(Unit.value)
        } catch {
            return .failure(.generic("Unexpected error: \(error.localizedDescription)"))
        }
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
