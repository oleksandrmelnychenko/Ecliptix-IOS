//
//  NetworkServiceManager.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

class RpcServiceManager {
    private let unaryRpcService: UnaryRpcService
    private let receiveStreamExecutor: ReceiveStreamRpcService
    private let secrecyChannelRpcService: SecrecyChannelRpcService
        
    init(
        unaryRpcService: UnaryRpcService,
        receiveStreamExecutor: ReceiveStreamRpcService,
        secrecyChannelRpcService: SecrecyChannelRpcService)
    {
        self.unaryRpcService = unaryRpcService
        self.receiveStreamExecutor = receiveStreamExecutor
        self.secrecyChannelRpcService = secrecyChannelRpcService
    }
    
    public func establishAppDeviceSecrecyChannel(
        serviceRequest: SecrecyKeyExchangeServiceRequest<Ecliptix_Proto_PubKeyExchange, Ecliptix_Proto_PubKeyExchange>
    ) async -> Result<Ecliptix_Proto_PubKeyExchange, EcliptixProtocolFailure> {
        
        do {
            let response = try await secrecyChannelRpcService.establishAppDeviceSecrecyChannel(request: serviceRequest.pubKeyExchange)
            return response
        } catch {
            return .failure(.unexpectedError("Error during establish app device secrecy channel", inner: error))
        }
    }
    
    public func restoreAppDeviceSecrecyChannel(
        serviceRequest: SecrecyKeyExchangeServiceRequest<Ecliptix_Proto_RestoreSecrecyChannelRequest, Ecliptix_Proto_RestoreSecrecyChannelResponse>
    ) async -> Result<Ecliptix_Proto_RestoreSecrecyChannelResponse, EcliptixProtocolFailure> {
        
        do {
            let restoreSecrecyChannelResult = try await secrecyChannelRpcService.restoreAppDeviceSecrecyChannelAsync(request: serviceRequest.pubKeyExchange)
            return restoreSecrecyChannelResult
        } catch {
            return .failure(.unexpectedError("Error during restore app device secrecy channel.", inner: error))
        }
    }
    
    public func invokeServiceRequestAsync(request: ServiceRequest, token: CancellationToken) async throws -> Result<RpcFlow, EcliptixProtocolFailure> {
        
        let action = request.rcpServiceMethod
                
        if request.actionType == .single {
            let result = try await unaryRpcService.invokeRequestAsync(request: request, cancellation: token)
            return result
            
        } else if request.actionType == .receiveStream {
            let result: Result<RpcFlow, EcliptixProtocolFailure> = receiveStreamExecutor.processRequestAsync(request: request)
            return result
            
        } else {
            let result: Result<RpcFlow, EcliptixProtocolFailure> = .failure(.generic("Unhandled action type"))
            return result
        }
    }
}
