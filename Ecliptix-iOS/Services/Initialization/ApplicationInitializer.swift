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
    private let localizationService: LocalizationService
    private let systemEvents: SystemEventsProtocol
    
    init(
        networkProvider: NetworkProvider,
        secureStorageProvider: SecureStorageProviderProtocol,
        localizationService: LocalizationService,
        systemEvents: SystemEventsProtocol
    ) {
        self.networkProvider = networkProvider
        self.secureStorageProvider = secureStorageProvider
        self.localizationService = localizationService
        self.systemEvents = systemEvents
    }
    
    public func initializeAsync(defaultSystemSettings: DefaultSystemSettings) async -> Bool {
        
        do {
            self.systemEvents.publish(.new(.initializing))
            
            let settingsResult = self.secureStorageProvider.initApplicationInstanceSettings()
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
                Logger.error("Device registration failed: \(try registrationResult.unwrapErr())", category: "AppInit")
                return false
            }

            AppSettingsService.shared.setSettings(settings)
            
            Logger.info("Application initialized successfully", category: "AppInit")
            
            self.systemEvents.publish(.new(.running))
            return true
            
        } catch {
            Logger.error("An unhandled error occurred during application initialization: \(error)", category: "AppInit")
            return false
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
    ) async -> Result<Unit, InternalValidationFailure> {
        return await RequestPipeline.run(
            requestResult: RequestBuilder.buildRegisterAppDeviceRequest(settings: settings),
            pubKeyExchangeType: .dataCenterEphemeralConnect,
            serviceType: .registerAppDevice,
            flowType: .single,
            cancellationToken: CancellationToken(),
            networkProvider: self.networkProvider,
            parseAndValidate: { (response: Ecliptix_Proto_AppDevice_AppDeviceRegisteredStateReply) in
                                
                guard response.status == .successAlreadyExists || response.status == .successNewRegistration else {
                    return .failure(.networkError("Error during registration Device: \(response.status)"))
                }
                
                return .success(response)
            }
        )
        .Match(
            onSuccess: { response in
                do {
                    let appServerInstanceId = try Helpers.fromDataToGuid(response.uniqueID)
                    
                    
                    settings.systemDeviceIdentifier = appServerInstanceId.uuidString
                    settings.serverPublicKey = response.serverPublicKey
                    
                    Logger.info("Device successfully registered with server ID: \(appServerInstanceId)", category: "AppInit")
                    
                    return .success(.value)
                } catch {
                    return .failure(.internalServiceApi("Failed to parse reply", inner: error))
                }
            },
            onFailure: { error in .failure(error) }
        )
    }
}
