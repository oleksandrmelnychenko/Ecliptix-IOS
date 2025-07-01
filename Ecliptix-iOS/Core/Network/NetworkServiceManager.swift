//
//  NetworkServiceManager.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

internal class NetworkServiceManager {
    private let singleCallExecutor: SingleCallExecutor
    private let receiveStreamExecutor: ReceiveStreamExecutor
    private let keyExchangeExecutor: KeyExchangeExecutor
    
    private var activeStreamHandles = [RcpServiceAction: Task<Void, Never>]()
    
    init(singleCallExecutor: SingleCallExecutor, receiveStreamExecutor: ReceiveStreamExecutor, keyExchangeExecutor: KeyExchangeExecutor) {
        self.singleCallExecutor = singleCallExecutor
        self.receiveStreamExecutor = receiveStreamExecutor
        self.keyExchangeExecutor = keyExchangeExecutor
    }
    
    public func beginDataCenterPublicKeyExchange(action: PubKeyExchangeActionInvokable) async {
        
        do {
            let beginPubKeyExchangeResult = try await keyExchangeExecutor.beginDataCenterPublicKeyExchange(request: action.pubKeyExchange)
            
            if beginPubKeyExchangeResult.isOk {
                if action.onComplete != nil {
                    try action.onComplete?(beginPubKeyExchangeResult.unwrap())
                }
            }
        } catch {
            debugPrint("Error during public key exchange: \(error)")
        }
    }
    
    public func invokeServiceRequestAsync(request: ServiceRequest, token: CancellationToken) async throws -> Result<RpcFlow, EcliptixProtocolFailure> {
        
        let action = request.rcpServiceMethod
                
        if request.actionType == .single {
            let result: Result<RpcFlow, EcliptixProtocolFailure> = try await singleCallExecutor.invokeRequestAsync(request: request, cancellation: token)
            
            print("Action \(action) executed successfullt for req_id: \(request.reqId)")
            return result
        } else if request.actionType == .receiveStream {
            let result: Result<RpcFlow, EcliptixProtocolFailure> = receiveStreamExecutor.processRequestAsync(request: request)
            
            print("Action \(action) executed successfullt for req_id: \(request.reqId)")
            return result
        } else {
            let result: Result<RpcFlow, EcliptixProtocolFailure> = .failure(.generic("Unhandled action type"))
            
            print("Action \(action) executed successfullt for req_id: \(request.reqId)")
            return result
        }
    }
}
