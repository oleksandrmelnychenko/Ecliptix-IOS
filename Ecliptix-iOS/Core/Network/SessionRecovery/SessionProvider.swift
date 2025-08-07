//
//  SessionProvider.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 16.07.2025.
//

import Foundation

final class SessionProvider: SessionRecoveryStrategy {
    
    private static let defaultOneTimeKeyCount: UInt32 = 5
    
    private let rpcMetaDataProvider: RpcMetaDataProviderProtocol
    private let secureStorageProvider: SecureStorageProviderProtocol
    private let rpcServiceManager: RpcServiceManager
    private let networkEvents: NetworkEventsProtocol
    private let systemEvents: SystemEventsProtocol
    
    private lazy var sessionLock = SessionLock(sessionProvider: self)
    
    private var isSessionConsiderdHealthy: Bool
    
    init(
        rpcMetaDataProvider: RpcMetaDataProviderProtocol,
        secureStorageProvider: SecureStorageProviderProtocol,
        rpcServiceManager: RpcServiceManager,
        networkEvents: NetworkEventsProtocol,
        systemEvents: SystemEventsProtocol,
    ) {
        self.rpcMetaDataProvider = rpcMetaDataProvider
        self.secureStorageProvider = secureStorageProvider
        self.rpcServiceManager = rpcServiceManager
        self.networkEvents = networkEvents
        self.systemEvents = systemEvents
        
        self.isSessionConsiderdHealthy = false
    }
    
    func establishSession(
        settings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings,
        shouldBeRecovered: Bool
    ) async -> Result<UInt32, NetworkFailure> {
        do {
            let connectId = AppSettingsService.computeUniqueConnectId(
                settings: settings,
                pubKeyExchangeType: .dataCenterEphemeralConnect
            )
            
            if shouldBeRecovered {
                let storedStateResult = self.secureStorageProvider.tryGetByKey(key: String(connectId))

                if storedStateResult.isOk, let data = try? storedStateResult.unwrap() {
                    let state = try Ecliptix_Proto_KeyMaterials_EcliptixSessionState(serializedBytes: data)
                    let restoreResult = await self.restoreSecrecyChannel(
                        ecliptixSecrecyChannelState: state,
                        applicationInstanceSettings: settings)

                    if restoreResult.isOk, let isSuccessedRestored = try? restoreResult.unwrap(), isSuccessedRestored == true {
                        Logger.info("Successfully restored and synchronized secrecy channel \(connectId)", category: "AppInit")
                        return .success(connectId)
                    }

                    Logger.warning("Failed to restore secrecy channel or it was out of sync. A new channel will be established", category: "AppInit")
                }
            }
            
            await withCheckedContinuation { continuation in
                Task {
                    await self.initiateEcliptixProtocolSystem(applicationInstanceSettings: settings, connectId: connectId)
                    continuation.resume()
                }
            }
            let establishResult = await self.establishSecrecyChannel(connectId: connectId)
            
            guard establishResult.isOk else {
                return .failure(try establishResult.unwrapErr())
            }
            
            let secrecyChannelState = try establishResult.unwrap()
            let storeResult = secureStorageProvider.store(key: String(connectId), data: try secrecyChannelState.serializedData())
            
            switch storeResult {
            case .success:
//                logger.log(.info, "Successfully established new secrecy channel \(connectId)", category: "AppInit")
                return .success(connectId)
            case .failure(let error):
                return .failure(.unexpectedError("An unhandled error occurred while storing the secrecy channel state", inner: error))
            }
        } catch {
            return .failure(.unexpectedError("An unhandled error occurred while ensuring the secrecy channel", inner: error))
        }
    }

    func restoreSecrecyChannelAsync() async -> Result<Unit, NetworkFailure> {
        await sessionLock.restoreSecrecyChannelAsync()
    }
    
    func initiateEcliptixProtocolSystem(
        applicationInstanceSettings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings,
        connectId: UInt32
    ) async {
        do {
            AppSettingsService.shared.setSettings(applicationInstanceSettings)
            
            let identityKeys = try EcliptixSystemIdentityKeys.create(oneTimeKeyCount: Self.defaultOneTimeKeyCount).unwrap()
            let protocolSystem = EcliptixProtocolSystem(ecliptixSystemIdentityKeys: identityKeys)
            
            ConnectionStore.shared.set(for: connectId, system: protocolSystem)
            
            let appInstanceId = try Helpers.fromDataToGuid(applicationInstanceSettings.appInstanceID)
            let deviceId = try Helpers.fromDataToGuid(applicationInstanceSettings.deviceID)
            
            self.rpcMetaDataProvider.setAppInfo(appInstanceId: appInstanceId, deviceId: deviceId)
        } catch {
            debugPrint("Failed during creating Ecliptix system: \(error.localizedDescription)")
        }
    }
    
    actor SessionLock {
        unowned let sessionProvider: SessionProvider
        
        init(sessionProvider: SessionProvider) {
            self.sessionProvider = sessionProvider
        }
        
        func restoreSecrecyChannelAsync() async -> Result<Unit, NetworkFailure> {
            if self.sessionProvider.isSessionConsiderdHealthy {
                debugPrint("Session was already recovered by another thread. Skipping redundant recovery")
                return .success(.value)
            }

            debugPrint("Starting session recovery process...")
            let result = await self.sessionProvider.perfromFullRecoveryLogic()
            
            self.sessionProvider.isSessionConsiderdHealthy = result.isOk
            if result.isErr {
                debugPrint("\(try! result.unwrapErr()) session recovery failed")
            }

            return result
        }
    }
    
    func setSecrecyChannelAsUnhealthy() {
        self.isSessionConsiderdHealthy = false
        debugPrint("Sesion marked unhealthy")
    }
    
    func restoreSecrecyChannel(
        ecliptixSecrecyChannelState: Ecliptix_Proto_KeyMaterials_EcliptixSessionState,
        applicationInstanceSettings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings
    ) async -> Result<Bool, NetworkFailure> {
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
    
    func establishSecrecyChannel(
        connectId: UInt32
    ) async -> Result<Ecliptix_Proto_KeyMaterials_EcliptixSessionState, NetworkFailure> {
        
        guard let protocolSystem = ConnectionStore.shared.get(for: connectId) else {
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
    
    private func perfromFullRecoveryLogic() async -> Result<Unit, NetworkFailure> {
        let getSettingsResult = AppSettingsService.shared.getSettings()

        guard case let .success(settings) = getSettingsResult else {
            return .failure(.unexpectedError("Missing app settings"))
        }

        let connectId = AppSettingsService.computeUniqueConnectId(
            settings: settings,
            pubKeyExchangeType: .dataCenterEphemeralConnect
        )

        ConnectionStore.shared.remove(for: connectId)

        let storedResult = self.secureStorageProvider.tryGetByKey(key: String(connectId))
        switch storedResult {
        case .success(let maybeData):
            if let data = maybeData {
                do {
                    let state = try Ecliptix_Proto_KeyMaterials_EcliptixSessionState(serializedBytes: data)
                    let restoreResult = await restoreSecrecyChannel(
                        ecliptixSecrecyChannelState: state,
                        applicationInstanceSettings: settings
                    )

                    switch restoreResult {
                    case .success(true):
                        debugPrint("Session successfully restored from storage")
                        return .success(.value)

                    default:
                        debugPrint("Failed to restore session from storage, will attempt full re-establishment")
                        break
                    }

                } catch {
                    return .failure(.unexpectedError("Failed to deserialize EcliptixSessionState", inner: error))
                }
            }
        case .failure(let error):
            debugPrint("Failed to load session state: \(error)")
            break
        }

        await self.initiateEcliptixProtocolSystem(applicationInstanceSettings: settings, connectId: connectId)

        let establishResult = await establishSecrecyChannel(connectId: connectId)

        switch establishResult {
        case .success(let state):
            do {
                let data = try state.serializedData()
                let storeResult = self.secureStorageProvider.store(key: String(connectId), data: data)

                if case .failure(let storeError) = storeResult {
                    debugPrint("Failed to store newly established session state: \(storeError.message)")
                }

                debugPrint("Session successfully established via new key exchange")
                return .success(.value)

            } catch {
                return .failure(.unexpectedError("Failed to serialize EcliptixSessionState", inner: error))
            }

        case .failure(let establishError):
            return .failure(establishError)
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
            
            ConnectionStore.shared.set(for: currentState.connectID, system: system)
            
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
