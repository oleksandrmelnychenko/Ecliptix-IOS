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
    
    private var serviceInvokers: [ServiceFlowType: GrpcMethodDelegate] = [:]
    typealias GrpcMethodDelegate = (_ request: ServiceRequest, _ token: CancellationToken) async throws -> Result<RpcFlow, EcliptixProtocolFailure>
        
    init(
        unaryRpcService: UnaryRpcService,
        receiveStreamExecutor: ReceiveStreamRpcService,
        secrecyChannelRpcService: SecrecyChannelRpcService)
    {
        self.unaryRpcService = unaryRpcService
        self.receiveStreamExecutor = receiveStreamExecutor
        self.secrecyChannelRpcService = secrecyChannelRpcService
        
        self.serviceInvokers = [
            .single: self.unaryRpcService.invokeRequestAsync,
            .receiveStream: self.receiveStreamExecutor.processRequestAsync
        ]
    }
    
    public func establishAppDeviceSecrecyChannel(
        serviceRequest: SecrecyKeyExchangeServiceRequest<Ecliptix_Proto_PubKeyExchange, Ecliptix_Proto_PubKeyExchange>
    ) async -> Result<Ecliptix_Proto_PubKeyExchange, EcliptixProtocolFailure> {
        
        return await Result<Ecliptix_Proto_PubKeyExchange, EcliptixProtocolFailure>.TryAsync {
            try await self.secrecyChannelRpcService.establishAppDeviceSecrecyChannel(request: serviceRequest.pubKeyExchange).unwrap()
        }.mapError { error in
            EcliptixProtocolFailure.unexpectedError("Error during establish app device secrecy channel", inner: error)
        }
    }
    
    public func restoreAppDeviceSecrecyChannel(
        serviceRequest: SecrecyKeyExchangeServiceRequest<Ecliptix_Proto_RestoreSecrecyChannelRequest, Ecliptix_Proto_RestoreSecrecyChannelResponse>
    ) async -> Result<Ecliptix_Proto_RestoreSecrecyChannelResponse, EcliptixProtocolFailure> {
        
        return await Result<Ecliptix_Proto_RestoreSecrecyChannelResponse, EcliptixProtocolFailure>.TryAsync {
            try await self.secrecyChannelRpcService.restoreAppDeviceSecrecyChannelAsync(request: serviceRequest.pubKeyExchange).unwrap()
        }.mapError { error in
            EcliptixProtocolFailure.unexpectedError("Error during establish app device secrecy channel", inner: error)
        }
    }
    
    public func invokeServiceRequestAsync(request: ServiceRequest, token: CancellationToken) async -> Result<RpcFlow, EcliptixProtocolFailure> {
        
        guard let invoker = self.serviceInvokers[request.actionType] else {
            return .failure(.invalidInput("Unsupported invoker"))
        }
        
        do {
            let task = try await invoker(request, token)
            
            switch task {
            case .success:
                print("Action \(request.rcpServiceMethod) executed successfully for req_id: \(request.reqId)")
            case .failure:
                print("Action \(request.rcpServiceMethod) failed for req_id: \(request.reqId). Error: \(try task.unwrapErr())")
            }
            
            return task
        } catch {
            return .failure(.unexpectedError("Invocation failed", inner: error))
        }
    }
}
