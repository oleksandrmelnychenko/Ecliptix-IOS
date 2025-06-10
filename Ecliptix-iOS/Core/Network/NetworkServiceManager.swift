//
//  NetworkServiceManager.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

public class NetworkServiceManager {
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
            let beginPubKeyExchangeResult = await keyExchangeExecutor.beginDataCenterPublicKeyExchange(request: action.pubKeyExchange)
            
            if beginPubKeyExchangeResult.isOk {
                if action.onComplete != nil {
                    try action.onComplete?(beginPubKeyExchangeResult.unwrap())
                }
            }
        } catch {
            
        }

    }
    
    public func invokeServiceRequestAsync(request: ServiceRequest, token: CancellationToken) async -> Result<RpcFlow, EcliptixProtocolFailure> {
        
        let action = request.rcpServiceMethod
        
        var result: Result<RpcFlow, EcliptixProtocolFailure> = .failure(.generic("Unhandled action type"))
        
        if request.actionType == .single {
            result = await singleCallExecutor.invokeRequestAsync(request: request, token: token)
        } else if request.actionType == .receiveStream {
            result = receiveStreamExecutor.processRequestAsync(request: request, token: token)
        }
        
        print("Action \(action) executed successfullt for req_id: \(request.reqId)")
        return result
    }
}
