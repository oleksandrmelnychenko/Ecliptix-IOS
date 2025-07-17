//
//  SessionProvider.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 16.07.2025.
//

struct SessionProvider {
    
    public static func establishSession(
        settings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings
    ) async -> Result<UInt32, NetworkFailure> {
        do {
            let networkProvider: NetworkProvider
            let secureStorageProvider: SecureStorageProviderProtocol
            do {
                networkProvider = try ServiceLocator.shared.resolve(NetworkProvider.self)
                secureStorageProvider = try ServiceLocator.shared.resolve(SecureStorageProviderProtocol.self)
            } catch {
                return .failure(.unexpectedError("", inner: error))
            }
            
            let connectId = NetworkProvider.computeUniqueConnectId(
                applicationInstanceSettings: settings,
                pubKeyExchangeType: .dataCenterEphemeralConnect)
            
            
            await withCheckedContinuation { continuation in
                Task {
                    await networkProvider.initiateEcliptixProtocolSystem(applicationInstanceSettings: settings, connectId: connectId)
                    continuation.resume()
                }
            }
            let establishResult = await networkProvider.establishSecrecyChannel(connectId: connectId)
            
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
    
    public static func recoverSession(
        settings: inout Ecliptix_Proto_AppDevice_ApplicationInstanceSettings
    ) async {
        do {
            let establishSessionResult = await establishSession(settings: settings)
            
            guard establishSessionResult.isOk else {
    //            logger.log(.error, "Failed to establish or restore secrecy channel: \(try connectIdResult.unwrapErr())", category: "AppInit")
                return
            }
            
            let connectId = try establishSessionResult.unwrap()
            
            let registrationResult = await self.registerDeviceAsync(connectId: connectId, settings: &settings)
            guard registrationResult.isOk else {
    //            logger.log(.error, "Device registration failed: \(try! registrationResult.unwrapErr())", category: "AppInit")
                return
            }
        } catch {
            
        }

    }
    
    private static func registerDeviceAsync(
        connectId: UInt32,
        settings: inout Ecliptix_Proto_AppDevice_ApplicationInstanceSettings
    ) async -> Result<Unit, NetworkFailure> {
        
        let networkProvider: NetworkProvider
        let secureStorageProvider: SecureStorageProviderProtocol
        do {
            networkProvider = try ServiceLocator.shared.resolve(NetworkProvider.self)
            secureStorageProvider = try ServiceLocator.shared.resolve(SecureStorageProviderProtocol.self)
        } catch {
            return .failure(.unexpectedError("", inner: error))
        }
        
        var newSettings = settings
        
        var appDevice = Ecliptix_Proto_AppDevice_AppDevice()
        appDevice.appInstanceID = settings.appInstanceID
        appDevice.deviceID = settings.deviceID
        appDevice.deviceType = .mobile
        
        do {
            let result = try await networkProvider.executeServiceAction(
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
                        
//                        self.logger.log(.info, "Device successfully registered with server ID: \(appServerInstanceId)", category: "AppInit")

                        return .success(.value)
                    } catch {
                        return .failure(.unexpectedError("Failed to parse reply", inner: error))
                    }
                },
                token: nil)
            
            settings = newSettings
            
            _ = secureStorageProvider.store(key: "ApplicationInstanceSettings", data: try settings.serializedData())
            
            return result
        } catch {
            return .failure(.unexpectedError("An unexpected error occurred during device registration", inner: error))
        }
    }
}
