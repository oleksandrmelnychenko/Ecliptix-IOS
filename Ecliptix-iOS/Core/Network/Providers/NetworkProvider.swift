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
    
    private let secureStorageProvider: SecureStorageProviderProtocol
    private let rpcMetaDataProvider: RpcMetaDataProviderProtocol
    private let rpcServiceManager: RpcServiceManager
    
    private var connections: [UInt32: EcliptixProtocolSystem] = [:]
    private let lock = DispatchSemaphore(value: 1)
    private var isSessionConsiderdHealthy: Bool = false
    
    private var applicationInstanceSettings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings? = nil
    
    private lazy var sessionLock = SessionLock(networkProvider: self)
    
    init(secureStorageProvider: SecureStorageProviderProtocol, rpcMetaDataProvider: RpcMetaDataProviderProtocol, rpcServiceManager: RpcServiceManager) {
        self.secureStorageProvider = secureStorageProvider
        self.rpcMetaDataProvider = rpcMetaDataProvider
        self.rpcServiceManager = rpcServiceManager
    }
    
    func initiateEcliptixProtocolSystem(applicationInstanceSettings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings, connectId: UInt32) async {
        do {
            self.applicationInstanceSettings = applicationInstanceSettings
            
            let identityKeys = try EcliptixSystemIdentityKeys.create(oneTimeKeyCount: Self.defaultOneTimeKeyCount).unwrap()
            let protocolSystem = EcliptixProtocolSystem(ecliptixSystemIdentityKeys: identityKeys)
            
            self.connections[connectId] = protocolSystem
            
            let appInstanceId = try Utilities.fromDataToGuid(applicationInstanceSettings.appInstanceID)
            let deviceId = try Utilities.fromDataToGuid(applicationInstanceSettings.deviceID)
            
            self.rpcMetaDataProvider.setAppInfo(appInstanceId: appInstanceId, deviceId: deviceId)
        } catch {
            debugPrint("Failed during creating Ecliptix system: \(error.localizedDescription)")
        }
    }
    
    func setSecrecyChannelAsUnhealthy() {
        self.isSessionConsiderdHealthy = false
        print("Sesion marked unhealthy")
    }
    
    func restoreSecrecyChannelAsync() async -> Result<Unit, EcliptixProtocolFailure> {
        await sessionLock.restoreSecrecyChannelAsync()
    }
    
    actor SessionLock {
        unowned let networkProvider: NetworkProvider
        
        init(networkProvider: NetworkProvider) {
            self.networkProvider = networkProvider
        }
        
        func restoreSecrecyChannelAsync() async -> Result<Unit, EcliptixProtocolFailure> {
            if self.networkProvider.isSessionConsiderdHealthy {
                print("Session was already recovered by another thread. Skipping redundant recovery")
                return .success(.value)
            }

            print("Starting session recovery process...")
            let result = await self.networkProvider.perfromFullRecoveryLogic()
            
            self.networkProvider.isSessionConsiderdHealthy = result.isOk
            if result.isErr {
                print("\(try! result.unwrapErr()) session recovery failed")
            }

            return result
        }
    }
    
    private func perfromFullRecoveryLogic() async -> Result<Unit, EcliptixProtocolFailure> {
        let connectId = Self.computeUniqueConnectId(
            applicationInstanceSettings: self.applicationInstanceSettings!,
            pubKeyExchangeType: .dataCenterEphemeralConnect)
        
        self.connections.removeValue(forKey: connectId)
        
        do {
            let storedStateResult = secureStorageProvider.tryGetByKey(key: String(connectId))
            if storedStateResult.isOk, let data = try? storedStateResult.unwrap() {
                let state = try Ecliptix_Proto_EcliptixSecrecyChannelState(serializedBytes: data)
                let restoreResult = await restoreSecrecyChannel(
                    ecliptixSecrecyChannelState: state,
                    applicationInstanceSettings: self.applicationInstanceSettings!)
                if restoreResult.isOk, let isSuccessedRestored = try? restoreResult.unwrap(), isSuccessedRestored == true {
                    print("Session successfully restored from storage")
                    return .success(.value)
                }
                
                print("Failed to restore session from storage, will attempt full re-establishment")
            }
            
            await self.initiateEcliptixProtocolSystem(applicationInstanceSettings: self.applicationInstanceSettings!, connectId: connectId)
            
            let establishResult = await establishSecrecyChannel(connectId: connectId)
            guard establishResult.isOk else {
                return .failure(try establishResult.unwrapErr())
            }
            
            let storedResult = secureStorageProvider.store(key: String(connectId), data: try establishResult.unwrap().serializedData())
            if storedResult.isErr {
                print("Failed to store newly established session state: \(try storedResult.unwrapErr())")
            }
            
            print("Session successfully established via new key exchange")
            return .success(.value)
        } catch {
            return .failure(.unexpectedError("An unhandled error occurred during full recovery logic", inner: error))
        }
    }
    
    static func computeUniqueConnectId(applicationInstanceSettings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings, pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType) -> UInt32 {
        
        return Utilities.computeUniqueConnectId(
            appInstanceId: applicationInstanceSettings.appInstanceID,
            appDeviceId: applicationInstanceSettings.deviceID,
            contextType: pubKeyExchangeType)
    }
    
    func executeServiceAction(
        connectId: UInt32,
        serviceType: RpcServiceType,
        plainBuffer: Data,
        flowType: ServiceFlowType,
        onSuccessCallback: @escaping (Data) async -> Result<Unit, EcliptixProtocolFailure>,
        token: CancellationToken? = CancellationToken()
    ) async throws -> Result<Unit, EcliptixProtocolFailure> {
        guard let protocolSystem = connections[connectId] else {
            return .failure(.generic("Connection not found"))
        }
        
        do {
            return try await sendRequest(
                connectId: connectId,
                protocolSystem: protocolSystem,
                onSuccessCallback: onSuccessCallback,
                buildRequest(protocolSystem: protocolSystem, plainBuffer: plainBuffer, flowType: flowType, serviceType: serviceType)
            )
        } catch {
            switch SessionError.parse(from: error) {
            case .sessionExpired:
                if serviceType == .registerAppDevice {
                    _ = await self.restoreSecrecyChannelAsync()
                } else {
                    _ = await ApplicationInitializer().initializeAsync()
                }
                
                guard let protocolSystem = connections[connectId] else {
                    return .failure(.generic("Connection not found"))
                }

                do {
                    return try await sendRequest(
                        connectId: connectId,
                        protocolSystem: protocolSystem,
                        onSuccessCallback: onSuccessCallback,
                        buildRequest(protocolSystem: protocolSystem, plainBuffer: plainBuffer, flowType: flowType, serviceType: serviceType)
                    )
                } catch {
                    return .failure(.generic("Reattempt after session expired failed", inner: error))
                }

            case .other(let inner):
                throw inner
            }
        }
    }
    
    func buildRequest(
        protocolSystem: EcliptixProtocolSystem,
        plainBuffer: Data,
        flowType: ServiceFlowType,
        serviceType: RpcServiceType
    ) throws -> ServiceRequest {
        let outboundPayload = try protocolSystem.produceOutboundMessage(
            plainPayload: plainBuffer
        )
        
        return ServiceRequest.new(
            actionType: flowType,
            rcpServiceMethod: serviceType,
            payload: try outboundPayload.unwrap(),
            encryptedChunls: []
        )
    }
    
    private func sendRequest(
        connectId: UInt32,
        protocolSystem: EcliptixProtocolSystem,
        onSuccessCallback: @escaping (Data) async -> Result<Unit, EcliptixProtocolFailure>,
        _ request: ServiceRequest
    ) async throws -> Result<Unit, EcliptixProtocolFailure> {
        let invokeResult = await rpcServiceManager.invokeServiceRequestAsync(request: request, token: CancellationToken())

        if invokeResult.isErr {
            throw try invokeResult.unwrapErr().innerError ?? invokeResult.unwrapErr()
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
                    let callbackOutcome = await onSuccessCallback(try decryptedData.unwrap())
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
                return .failure(.generic("Unsupported stream type"))

            default:
                return .failure(.generic("Unsupported stream type"))
        }

        return .success(Unit.value)
    }

    public func restoreSecrecyChannel(
        ecliptixSecrecyChannelState: Ecliptix_Proto_EcliptixSecrecyChannelState,
        applicationInstanceSettings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings
    ) async -> Result<Bool, EcliptixProtocolFailure> {
        if self.applicationInstanceSettings == nil {
            self.applicationInstanceSettings = applicationInstanceSettings
        }
        
        do {
            self.rpcMetaDataProvider.setAppInfo(
                appInstanceId: try Utilities.fromDataToGuid(applicationInstanceSettings.appInstanceID),
                deviceId: try Utilities.fromDataToGuid(applicationInstanceSettings.deviceID))
            
            let request = Ecliptix_Proto_RestoreSecrecyChannelRequest()
            let serviceRequest = SecrecyKeyExchangeServiceRequest<Ecliptix_Proto_RestoreSecrecyChannelRequest, Ecliptix_Proto_RestoreSecrecyChannelResponse>.new(
                jobType: .single,
                method: .restoreSecrecyChannel,
                pubKeyExchange: request)
            
            let responseResult = await rpcServiceManager.restoreAppDeviceSecrecyChannel(serviceRequest: serviceRequest)
            if responseResult.isErr {
                return responseResult.map { _ in false }
            }
            let response = try responseResult.unwrap()
            
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
    
    public func establishSecrecyChannel(connectId: UInt32) async -> Result<Ecliptix_Proto_EcliptixSecrecyChannelState, EcliptixProtocolFailure> {
        
        guard let protocolSystem = connections[connectId] else {
            return .failure(.generic("Connection not found"))
        }
        
        do {
            let pubKeyExchange = try protocolSystem.beginDataCenterPubKeyExchange(connectId: connectId, exchangeType: .dataCenterEphemeralConnect)
            
            let action = SecrecyKeyExchangeServiceRequest<Ecliptix_Proto_PubKeyExchange, Ecliptix_Proto_PubKeyExchange>.new(
                jobType: .single,
                method: .establishSecrecyChannel,
                pubKeyExchange: try pubKeyExchange.unwrap())
            
            let peerPubKeyExchangeResult = await self.rpcServiceManager.establishAppDeviceSecrecyChannel(serviceRequest: action)
            guard peerPubKeyExchangeResult.isOk else {
                return .failure(try peerPubKeyExchangeResult.unwrapErr())
            }
            var peerPubKeyExchange = try peerPubKeyExchangeResult.unwrap()
            
            try protocolSystem.completeDataCenterPubKeyExchange(peerMessage: &peerPubKeyExchange)
            
            let idKeys = protocolSystem.getIdentityKeys()
            let connection = try protocolSystem.getConnection()

            let ecliptixSecrecyChannelStateResult = idKeys.toProtoState()
                .flatMap { identityKeysProto in connection.toProtoState()
                        .map { ratchetStateProto in
                            var ecliptixSecrecyChannelState = Ecliptix_Proto_EcliptixSecrecyChannelState()
                            ecliptixSecrecyChannelState.connectID = connectId
                            ecliptixSecrecyChannelState.identityKeys = identityKeysProto
                            ecliptixSecrecyChannelState.peerHandshakeMessage = peerPubKeyExchange
                            ecliptixSecrecyChannelState.ratchetState = ratchetStateProto
                            return ecliptixSecrecyChannelState
                        }

                }
            
            return ecliptixSecrecyChannelStateResult
        } catch {
            return .failure(.unexpectedError("An unexpected error occurred during establish Secrecy Channel", inner: error))
        }
    }
    
    private func syncSecrecyChannel(
        currentState: Ecliptix_Proto_EcliptixSecrecyChannelState,
        serverResponse: Ecliptix_Proto_RestoreSecrecyChannelResponse
    ) -> Result<Ecliptix_Proto_EcliptixSecrecyChannelState, EcliptixProtocolFailure> {
        
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
    
    private static func recreateSystemFromState(state: Ecliptix_Proto_EcliptixSecrecyChannelState) -> Result<EcliptixProtocolSystem, EcliptixProtocolFailure> {
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
    
    private static func createStateFromSystem(oldState: Ecliptix_Proto_EcliptixSecrecyChannelState, system: EcliptixProtocolSystem) -> Result<Ecliptix_Proto_EcliptixSecrecyChannelState, EcliptixProtocolFailure> {
        
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
