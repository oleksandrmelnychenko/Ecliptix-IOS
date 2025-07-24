//
//  NetworkController.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import Foundation
import SwiftProtobuf

final class NetworkProvider: NetworkProviderProtocol {
    private static let defaultOneTimeKeyCount: UInt32 = 5
    
    private let rpcMetaDataProvider: RpcMetaDataProviderProtocol
    private let secureStorageProvider: SecureStorageProviderProtocol
    private let rpcServiceManager: RpcServiceManager
    private let networkEvents: NetworkEventsProtocol
    private let systemEvents: SystemEventsProtocol
    
    private var connections: [UInt32: EcliptixProtocolSystem] = [:]
    private let lock = DispatchSemaphore(value: 1)
    private var isSessionConsiderdHealthy: Bool = false
    
    private var applicationInstanceSettings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings? = nil
    
    private lazy var sessionLock = SessionLock(networkProvider: self)
    
    init(
        secureStorageProvider: SecureStorageProviderProtocol,
        rpcMetaDataProvider: RpcMetaDataProviderProtocol,
        rpcServiceManager: RpcServiceManager,
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol
    ) {
        self.secureStorageProvider = secureStorageProvider
        self.rpcMetaDataProvider = rpcMetaDataProvider
        self.rpcServiceManager = rpcServiceManager
        self.networkEvents = networkEvents
        self.systemEvents = systemEvents
    }
    
    func initiateEcliptixProtocolSystem(
        applicationInstanceSettings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings,
        connectId: UInt32
    ) async {
        do {
            self.applicationInstanceSettings = applicationInstanceSettings
            
            let identityKeys = try EcliptixSystemIdentityKeys.create(oneTimeKeyCount: Self.defaultOneTimeKeyCount).unwrap()
            let protocolSystem = EcliptixProtocolSystem(ecliptixSystemIdentityKeys: identityKeys)
            
            self.connections[connectId] = protocolSystem
            
            let appInstanceId = try Helpers.fromDataToGuid(applicationInstanceSettings.appInstanceID)
            let deviceId = try Helpers.fromDataToGuid(applicationInstanceSettings.deviceID)
            
            self.rpcMetaDataProvider.setAppInfo(appInstanceId: appInstanceId, deviceId: deviceId)
        } catch {
            debugPrint("Failed during creating Ecliptix system: \(error.localizedDescription)")
        }
    }
    
    func setSecrecyChannelAsUnhealthy() {
        self.isSessionConsiderdHealthy = false
        debugPrint("Sesion marked unhealthy")
    }
    
    func restoreSecrecyChannelAsync() async -> Result<Unit, NetworkFailure> {
        await sessionLock.restoreSecrecyChannelAsync()
    }
    
    actor SessionLock {
        unowned let networkProvider: NetworkProvider
        
        init(networkProvider: NetworkProvider) {
            self.networkProvider = networkProvider
        }
        
        func restoreSecrecyChannelAsync() async -> Result<Unit, NetworkFailure> {
            if self.networkProvider.isSessionConsiderdHealthy {
                debugPrint("Session was already recovered by another thread. Skipping redundant recovery")
                return .success(.value)
            }

            debugPrint("Starting session recovery process...")
            let result = await self.networkProvider.perfromFullRecoveryLogic()
            
            self.networkProvider.isSessionConsiderdHealthy = result.isOk
            if result.isErr {
                debugPrint("\(try! result.unwrapErr()) session recovery failed")
            }

            return result
        }
    }
    
    private func perfromFullRecoveryLogic() async -> Result<Unit, NetworkFailure> {
        guard self.applicationInstanceSettings != nil else {
            return .failure(.invalidRequestType("Application instance settings not available"))
        }
        
        let connectId = Self.computeUniqueConnectId(
            applicationInstanceSettings: self.applicationInstanceSettings!,
            pubKeyExchangeType: .dataCenterEphemeralConnect)
        
        self.connections.removeValue(forKey: connectId)
        
        do {
            let storedStateResult = self.secureStorageProvider.tryGetByKey(key: String(connectId))
            
            if storedStateResult.isOk, let data = try? storedStateResult.unwrap() {
                let state = try Ecliptix_Proto_KeyMaterials_EcliptixSessionState(serializedBytes: data)
                let restoreResult = await restoreSecrecyChannel(
                    ecliptixSecrecyChannelState: state,
                    applicationInstanceSettings: self.applicationInstanceSettings!)
                if restoreResult.isOk, let isSuccessedRestored = try? restoreResult.unwrap(), isSuccessedRestored == true {
                    debugPrint("Session successfully restored from storage")
                    return .success(.value)
                }
                
                debugPrint("Failed to restore session from storage, will attempt full re-establishment")
            }
            
            await self.initiateEcliptixProtocolSystem(applicationInstanceSettings: self.applicationInstanceSettings!, connectId: connectId)
            
            let establishResult = await establishSecrecyChannel(connectId: connectId)
            guard establishResult.isOk else {
                return .failure(try establishResult.unwrapErr())
            }
            
            let storedResult = self.secureStorageProvider.store(key: String(connectId), data: try establishResult.unwrap().serializedData())
            if storedResult.isErr {
                debugPrint("Failed to store newly established session state: \(try storedResult.unwrapErr())")
            }
            
            debugPrint("Session successfully established via new key exchange")
            return .success(.value)
        } catch {
            return .failure(.unexpectedError("An unhandled error occurred during full recovery logic", inner: error))
        }
    }
    
    static func computeUniqueConnectId(
        applicationInstanceSettings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings,
        pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType
    ) -> UInt32 {
        return Helpers.computeUniqueConnectId(
            appInstanceId: applicationInstanceSettings.appInstanceID,
            appDeviceId: applicationInstanceSettings.deviceID,
            contextType: pubKeyExchangeType)
    }
    
    func executeServiceAction(
        connectId: UInt32,
        serviceType: RpcServiceType,
        plainBuffer: Data,
        flowType: ServiceFlowType,
        onSuccessCallback: @escaping (Data) async -> Result<Unit, NetworkFailure>,
        token: CancellationToken? = CancellationToken()
    ) async -> Result<Data, NetworkFailure> {
        
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
                    if serviceType == .registerAppDevice {
                        _ = await SessionProvider.establishSession(settings: self.applicationInstanceSettings!)
                    } else {
                        _ = await SessionProvider.recoverSession(settings: &self.applicationInstanceSettings!)
                    }
                })
                {
                    guard let protocolSystem = self.connections[connectId] else {
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
                        
                        return try await self.sendRequest(
                            connectId: connectId,
                            protocolSystem: protocolSystem,
                            onSuccessCallback: onSuccessCallback,
                            requestResult.unwrap()
                        )
                    } catch {
                        return .failure(.unexpectedError("Unhandled error during execution to reqeust.", inner: error))
                    }
                }
    }
    
    func buildRequest(
        protocolSystem: EcliptixProtocolSystem,
        plainBuffer: Data,
        flowType: ServiceFlowType,
        serviceType: RpcServiceType
    ) -> Result<ServiceRequest, NetworkFailure> {
        do {
            let outboundPayload = try protocolSystem.produceOutboundMessage(
                plainPayload: plainBuffer
            )
            
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
        onSuccessCallback: @escaping (Data) async -> Result<Unit, NetworkFailure>,
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

                case let inboundStream as RpcFlow.InboundStream:
                    do {
                        try await withTaskCancellationHandler(operation: {
                            for try await streamItem in inboundStream.stream {
                                if streamItem.isErr {
    //                                throw try streamItem.unwrapErr()
                                    continue
                                }

                                let streamPayload = try streamItem.unwrap()
                                let streamDecryptedData = try protocolSystem.processInboundMessage(cipherPayloadProto: streamPayload)

                                let streamCallbackOutcome = await onSuccessCallback(try streamDecryptedData.unwrap())
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
                    return .failure(.invalidRequestType("Unsupported stream type"))

                default:
                    return .failure(.invalidRequestType("Unsupported stream type"))
            }
            
            return .success(Data())
        } catch {
            return .failure(.unexpectedError("Unhandled error", inner: error))
        }
        
    }

    public func restoreSecrecyChannel(
        ecliptixSecrecyChannelState: Ecliptix_Proto_KeyMaterials_EcliptixSessionState,
        applicationInstanceSettings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings
    ) async -> Result<Bool, NetworkFailure> {
        if self.applicationInstanceSettings == nil {
            self.applicationInstanceSettings = applicationInstanceSettings
        }
        
        do {
            self.rpcMetaDataProvider.setAppInfo(
                appInstanceId: try Helpers.fromDataToGuid(applicationInstanceSettings.appInstanceID),
                deviceId: try Helpers.fromDataToGuid(applicationInstanceSettings.deviceID))
            
            let request = Ecliptix_Proto_RestoreSecrecyChannelRequest()
            let serviceRequest = SecrecyKeyExchangeServiceRequest<Ecliptix_Proto_RestoreSecrecyChannelRequest, Ecliptix_Proto_RestoreSecrecyChannelResponse>.new(
                jobType: .single,
                method: .restoreSecrecyChannel,
                pubKeyExchange: request)
            
            let restoreAppDeviceSecrecyChannelResponse = await rpcServiceManager.restoreAppDeviceSecrecyChannel(
                networkEvents: self.networkEvents,
                systemEvents: self.systemEvents,
                serviceRequest: serviceRequest)
            if restoreAppDeviceSecrecyChannelResponse.isErr {
                return .failure(try restoreAppDeviceSecrecyChannelResponse.unwrapErr())
            }
            let response = try restoreAppDeviceSecrecyChannelResponse.unwrap()
            
            if response.status == .sessionResumed {
                _ = syncSecrecyChannel(currentState: ecliptixSecrecyChannelState, serverResponse: response)
                return .success(true)
            }
            
            _ = syncSecrecyChannel(currentState: ecliptixSecrecyChannelState, serverResponse: response)
            return .success(false)
        } catch {
            return .failure(.unexpectedError("An unexpected error occurred during restoring secrecy channel", inner: error))
        }
    }
    
    public func establishSecrecyChannel(
        connectId: UInt32
    ) async -> Result<Ecliptix_Proto_KeyMaterials_EcliptixSessionState, NetworkFailure> {
        
        guard let protocolSystem = connections[connectId] else {
            return .failure(.invalidRequestType("Connection not found"))
        }
        
        do {
            let pubKeyExchange = try protocolSystem.beginDataCenterPubKeyExchange(connectId: connectId, exchangeType: .dataCenterEphemeralConnect)
            
            let action = SecrecyKeyExchangeServiceRequest<Ecliptix_Proto_PubKeyExchange, Ecliptix_Proto_PubKeyExchange>.new(
                jobType: .single,
                method: .establishSecrecyChannel,
                pubKeyExchange: try pubKeyExchange.unwrap())
            
            let establishAppDeviceSecrecyChannelResult = await self.rpcServiceManager.establishAppDeviceSecrecyChannel(
                networkEvents: self.networkEvents,
                systemEvents: self.systemEvents,
                serviceRequest: action)
            guard establishAppDeviceSecrecyChannelResult.isOk else {
                return .failure(try establishAppDeviceSecrecyChannelResult.unwrapErr())
            }
            var peerPubKeyExchange = try establishAppDeviceSecrecyChannelResult.unwrap()
            
            try protocolSystem.completeDataCenterPubKeyExchange(peerMessage: &peerPubKeyExchange)
            
            let idKeys = protocolSystem.getIdentityKeys()
            let connection = try protocolSystem.getConnection()

            let ecliptixSecrecyChannelStateResult = idKeys.toProtoState()
                .flatMap { identityKeysProto in connection.toProtoState()
                        .map { ratchetStateProto in
                            var ecliptixSecrecyChannelState = Ecliptix_Proto_KeyMaterials_EcliptixSessionState()
                            ecliptixSecrecyChannelState.connectID = connectId
                            ecliptixSecrecyChannelState.identityKeys = identityKeysProto
                            ecliptixSecrecyChannelState.peerHandshakeMessage = peerPubKeyExchange
                            ecliptixSecrecyChannelState.ratchetState = ratchetStateProto
                            return ecliptixSecrecyChannelState
                        }

                }
            
            return ecliptixSecrecyChannelStateResult.mapEcliptixProtocolFailure()
        } catch {
            return .failure(.unexpectedError("An unexpected error occurred during establish Secrecy Channel", inner: error))
        }
    }
    
    private func syncSecrecyChannel(
        currentState: Ecliptix_Proto_KeyMaterials_EcliptixSessionState,
        serverResponse: Ecliptix_Proto_RestoreSecrecyChannelResponse
    ) -> Result<Ecliptix_Proto_KeyMaterials_EcliptixSessionState, EcliptixProtocolFailure> {
        
        do {
            let systemResult = Self.recreateSystemFromState(state: currentState)
            guard systemResult.isOk else {
                return .failure(try systemResult.unwrapErr())
            }
            
            let system = try systemResult.unwrap()
            let connection = try system.getConnection()
            
            let syncResult = connection.syncWithRemoteState(
                remoteSendingChainLength: serverResponse.sendingChainLength,
                remoteReceivingChainLength: serverResponse.receivingChainLength)
            
            self.connections[currentState.connectID] = system
            
            guard syncResult.isOk else {
                return .failure(try syncResult.unwrapErr())
            }
            
            return Self.createStateFromSystem(oldState: currentState, system: system)
        } catch {
            return .failure(.unexpectedError("An unexpected error occurred during syncrhonization secrecy channel", inner: error))
        }

    }
    
    private static func recreateSystemFromState(
        state: Ecliptix_Proto_KeyMaterials_EcliptixSessionState
    ) -> Result<EcliptixProtocolSystem, EcliptixProtocolFailure> {
        do {
            let idKeysResult = EcliptixSystemIdentityKeys.fromProtoState(proto: state.identityKeys)
            guard idKeysResult.isOk else {
                return .failure(try idKeysResult.unwrapErr())
            }
            
            let connResult = EcliptixProtocolConnection.fromProtoState(connectId: state.connectID, proto: state.ratchetState)
            guard connResult.isOk else {
                try idKeysResult.unwrap().dispose()
                return .failure(try connResult.unwrapErr())
            }
            
            return EcliptixProtocolSystem.createFrom(keys: try idKeysResult.unwrap(), connection: try connResult.unwrap())
        } catch {
            return .failure(.unexpectedError("An unexpected error occurred during recreation system from state", inner: error))
        }
    }
    
    private static func createStateFromSystem(
        oldState: Ecliptix_Proto_KeyMaterials_EcliptixSessionState,
        system: EcliptixProtocolSystem
    ) -> Result<Ecliptix_Proto_KeyMaterials_EcliptixSessionState, EcliptixProtocolFailure> {
        
        do {
            return try system.getConnection().toProtoState().map { newRatchetState in
                var newState = oldState
                newState.ratchetState = newRatchetState
                return newState
            }
        } catch {
            return .failure(.unexpectedError("An unexpected error occurred during creation state from system", inner: error))
        }
    }
}
