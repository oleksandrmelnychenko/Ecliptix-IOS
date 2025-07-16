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
    private let networkEvents: NetworkEventsProtocol
    private let systemEvents: SystemEventsProtocol
    
    private var serviceInvokers: [ServiceFlowType: GrpcMethodDelegate] = [:]
    typealias GrpcMethodDelegate = (
        _ request: ServiceRequest,
        _ token: CancellationToken
    ) async throws -> Result<RpcFlow, NetworkFailure>
        
    init(
        unaryRpcService: UnaryRpcService,
        receiveStreamExecutor: ReceiveStreamRpcService,
        secrecyChannelRpcService: SecrecyChannelRpcService,
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol
    ) {
        self.unaryRpcService = unaryRpcService
        self.receiveStreamExecutor = receiveStreamExecutor
        self.secrecyChannelRpcService = secrecyChannelRpcService
        self.networkEvents = networkEvents
        self.systemEvents = systemEvents
        
        self.serviceInvokers = [
            .single: { req, token in
                await self.unaryRpcService.invokeRequestAsync(
                    networkEvents: networkEvents,
                    systemEvents: systemEvents,
                    request: req,
                    token: token)
            },
            .receiveStream: self.receiveStreamExecutor.processRequestAsync
        ]
    }
    
    public func establishAppDeviceSecrecyChannel(
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        serviceRequest: SecrecyKeyExchangeServiceRequest<Ecliptix_Proto_PubKeyExchange, Ecliptix_Proto_PubKeyExchange>
    ) async -> Result<Ecliptix_Proto_PubKeyExchange, NetworkFailure> {
        
        return await Result<Ecliptix_Proto_PubKeyExchange, NetworkFailure>.TryAsync {
            try await self.secrecyChannelRpcService.establishAppDeviceSecrecyChannel(
                networkEvents: networkEvents,
                systemEvents: systemEvents,
                request: serviceRequest.pubKeyExchange).unwrap()
        } errorMapper: { error in
            .unexpectedError("Error during establish app device secrecy channel", inner: error)
        }
    }
    
    public func restoreAppDeviceSecrecyChannel(
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
        serviceRequest: SecrecyKeyExchangeServiceRequest<Ecliptix_Proto_RestoreSecrecyChannelRequest, Ecliptix_Proto_RestoreSecrecyChannelResponse>
    ) async -> Result<Ecliptix_Proto_RestoreSecrecyChannelResponse, NetworkFailure> {
        
        return await Result<Ecliptix_Proto_RestoreSecrecyChannelResponse, NetworkFailure>.TryAsync {
            try await self.secrecyChannelRpcService.restoreAppDeviceSecrecyChannelAsync(
                networkEvents: networkEvents,
                systemEvents: systemEvents,
                request: serviceRequest.pubKeyExchange).unwrap()
        } errorMapper: { error in
            .unexpectedError("Error during establish app device secrecy channel", inner: error)
        }
    }
    
    public func invokeServiceRequestAsync(
        request: ServiceRequest,
        token: CancellationToken
    ) async -> Result<RpcFlow, NetworkFailure> {
        
        guard let invoker = self.serviceInvokers[request.actionType] else {
            return .failure(.invalidRequestType("Unsupported service method"))
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
