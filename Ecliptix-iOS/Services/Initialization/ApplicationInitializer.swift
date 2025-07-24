//
//  SessionExecutor.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 19.06.2025.
//

import Foundation

final class ApplicationInitializer: ApplicationInitializerProtocol {
    private let networkProvider: NetworkProvider
    private let secureStorageProvider: SecureStorageProviderProtocol
    private let systemEvents: SystemEventsProtocol
    
    init(
        networkProvider: NetworkProvider,
        secureStorageProvider: SecureStorageProviderProtocol,
        systemEvents: SystemEventsProtocol
    ) {
        self.networkProvider = networkProvider
        self.secureStorageProvider = secureStorageProvider
        self.systemEvents = systemEvents
    }
    
    public func initializeAsync() async -> Bool {
        
        do {
            self.systemEvents.publish(.new(.initializing))
            
            let settingsResult = getOrCreateInstanceSettingsAsync()
            guard settingsResult.isOk else {
                Logger.error("Failed to get or create application instance settings: \(try! settingsResult.unwrapErr())", category: "AppInit")
                self.systemEvents.publish(.new(.fatalError))
                return false
            }
            
            let result = try settingsResult.unwrap()
            var settings = result.settings
            let isNewInstance = result.isNewInstance

            let connectIdResult = await self.ensureSecrecyChannelAsync(settings: settings, isNewInstance: isNewInstance)
            guard connectIdResult.isOk else {
                Logger.error("Failed to establish or restore secrecy channel: \(try connectIdResult.unwrapErr())", category: "AppInit")
                return false
            }
            
            let connectId = try connectIdResult.unwrap()
            
            let registrationResult = await self.registerDeviceAsync(connectId: connectId, settings: &settings)
            guard registrationResult.isOk else {
                Logger.error("Device registration failed: \(try! registrationResult.unwrapErr())", category: "AppInit")
                return false
            }

            Logger.info("Application initialized successfully", category: "AppInit")
            
            self.systemEvents.publish(.new(.running))
            return true
            
        } catch {
            Logger.error("An unhandled error occurred during application initialization: \(error)", category: "AppInit")
            return false
        }
    }
    
    private func getOrCreateInstanceSettingsAsync() -> Result<InstanceSettingsResult, InternalServiceApiFailure> {
        let settingsKey = "ApplicationInstanceSettings"
                
        do {
            let getResult = self.secureStorageProvider.tryGetByKey(key: settingsKey)
            guard getResult.isOk else {
                return .failure(try getResult.unwrapErr())
            }
                        
            let maybeSettingsData = try getResult.unwrap()
            
            if let data = maybeSettingsData {
                let existingSettings = try Ecliptix_Proto_AppDevice_ApplicationInstanceSettings(serializedBytes: data)
                return .success(InstanceSettingsResult(settings: existingSettings, isNewInstance: false))
            }
            
            var newSettings = Ecliptix_Proto_AppDevice_ApplicationInstanceSettings()
            newSettings.appInstanceID = Helpers.guidToData(UUID(uuidString: "c9d02c08-09dc-4c43-a63a-a977d1275d67")!)
            newSettings.deviceID = Helpers.guidToData(UUID(uuidString: "732ba091-cb23-4933-b19f-afabd04695aa")!)
//            newSettings.culture = "en-US"
            
            let storeResult = secureStorageProvider.store(key: settingsKey, data: try newSettings.serializedData())
            
            switch storeResult {
            case .success:
                return .success(InstanceSettingsResult(settings: newSettings, isNewInstance: true))
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(.secureStoreUnknown("An unexpected error occurred while retrieving or storing instance settings", inner: error))
        }
    }
    
    public func ensureSecrecyChannelAsync(
        settings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings,
        isNewInstance: Bool
    ) async -> Result<UInt32, NetworkFailure> {
        do {
            let connectId = NetworkProvider.computeUniqueConnectId(
                applicationInstanceSettings: settings,
                pubKeyExchangeType: .dataCenterEphemeralConnect)
            
            if !isNewInstance {
                let storedStateResult = self.secureStorageProvider.tryGetByKey(key: String(connectId))
                
                
                if storedStateResult.isOk, let data = try? storedStateResult.unwrap() {
                    let state = try Ecliptix_Proto_KeyMaterials_EcliptixSessionState(serializedBytes: data)
                    let restoreResult = await self.networkProvider.restoreSecrecyChannel(
                        ecliptixSecrecyChannelState: state,
                        applicationInstanceSettings: settings)
                    
                    if restoreResult.isOk, let isSuccessedRestored = try? restoreResult.unwrap(), isSuccessedRestored == true {
                        Logger.info("Successfully restored and synchronized secrecy channel \(connectId)", category: "AppInit")
                        return .success(connectId)
                    }
                    
                    Logger.warning("Failed to restore secrecy channel or it was out of sync. A new channel will be established", category: "AppInit")
                }
            }
            
            await self.networkProvider.initiateEcliptixProtocolSystem(applicationInstanceSettings: settings, connectId: connectId)
            let establishResult = await self.networkProvider.establishSecrecyChannel(connectId: connectId)
            
            guard establishResult.isOk else {
                return .failure(try establishResult.unwrapErr())
            }
            
            let secrecyChannelState = try establishResult.unwrap()
            let storeResult = secureStorageProvider.store(key: String(connectId), data: try secrecyChannelState.serializedData())
            
            switch storeResult {
            case .success:
                Logger.info("Successfully established new secrecy channel \(connectId)", category: "AppInit")
                return .success(connectId)
            case .failure(let error):
                return .failure(.unexpectedError("An unhandled error occurred while storing the secrecy channel state", inner: error))
            }
        } catch {
            return .failure(.unexpectedError("An unhandled error occurred while ensuring the secrecy channel", inner: error))
        }
    }
    
    private func registerDeviceAsync(
        connectId: UInt32,
        settings: inout Ecliptix_Proto_AppDevice_ApplicationInstanceSettings
    ) async -> Result<Unit, NetworkFailure> {
        
        var newSettings = settings
        
        var appDevice = Ecliptix_Proto_AppDevice_AppDevice()
        appDevice.appInstanceID = settings.appInstanceID
        appDevice.deviceID = settings.deviceID
        appDevice.deviceType = .mobile
        
        do {
            let result = try await self.networkProvider.executeServiceAction(
                connectId: connectId,
                serviceType: .registerAppDevice,
                plainBuffer: appDevice.serializedData(),
                flowType: .single,
                onSuccessCallback: { decryptedPayload in
                    do {
                        let reply = try Helpers.parseFromBytes(Ecliptix_Proto_AppDevice_AppDeviceRegisteredStateReply.self, data: decryptedPayload)
                        
                        let appServerInstanceId = try Helpers.fromDataToGuid(reply.uniqueID)
                        
                        
                        newSettings.systemDeviceIdentifier = appServerInstanceId.uuidString
                        newSettings.serverPublicKey = reply.serverPublicKey
                        
                        Logger.info("Device successfully registered with server ID: \(appServerInstanceId)", category: "AppInit")
                        
                        return .success(.value)
                    } catch {
                        return .failure(.unexpectedError("Failed to parse reply", inner: error))
                    }
                },
                token: nil)
                .map { _ in Unit.value }
            
            settings = newSettings
            
            _ = self.secureStorageProvider.store(key: "ApplicationInstanceSettings", data: try settings.serializedData())
            
            return result
        } catch {
            return .failure(.unexpectedError("An unexpected error occurred during device registration", inner: error))
        }
    }
}
