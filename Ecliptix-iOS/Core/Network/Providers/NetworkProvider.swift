//
//  NetworkController.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import Foundation
import SwiftProtobuf

final class NetworkProvider: NetworkProviderProtocol {
    private let requestExecutor: RequestExecutor
    private let sessionProvider: SessionProvider
    private let secureStorageProvider: SecureStorageProviderProtocol
    
    init(requestExecutor: RequestExecutor, sessionProvider: SessionProvider, secureStorageProvider: SecureStorageProviderProtocol) {
        self.requestExecutor = requestExecutor
        self.sessionProvider = sessionProvider
        self.secureStorageProvider = secureStorageProvider
    }
    
    func executeServiceAction(
        connectId: UInt32,
        serviceType: RpcServiceType,
        plainBuffer: Data,
        token: CancellationToken,
    )async -> Result<Data, NetworkFailure> {
        await requestExecutor.executeServiceAction(
            connectId: connectId,
            serviceType: serviceType,
            plainBuffer: plainBuffer,
            flowType: .single,
            token: token,
            onRetry: { [weak self] settings, serviceType in
                guard let self else { return }
                
                if serviceType == .registerAppDevice {
                    _ = await self.sessionProvider.establishSession(settings: settings, shouldBeRecovered: false)
                } else {
                    _ = await self.recoverSession(settings: settings, shouldBeRecovered: false)
                }
            }
        )
    }
    
    func executeStreamServiceAction(
        connectId: UInt32,
        serviceType: RpcServiceType,
        plainBuffer: Data,
        token: CancellationToken? = CancellationToken()
    ) async -> Result<AsyncThrowingStream<Result<Data, NetworkFailure>, Error>, NetworkFailure> {
        await requestExecutor.executeStreamServiceAction(
            connectId: connectId,
            serviceType: serviceType,
            plainBuffer: plainBuffer,
            token: token
        )
    }
    
    func registerDeviceAsync(
        connectId: UInt32,
        settings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings
    ) async -> Result<Unit, InternalValidationFailure> {
        await RequestPipeline.run(
            requestResult: RequestBuilder.buildRegisterAppDeviceRequest(settings: settings),
            serviceType: .registerAppDevice,
            flowType: .single,
            cancellationToken: CancellationToken(),
            networkProvider: self,
            parseAndValidate: { (response: Ecliptix_Proto_AppDevice_AppDeviceRegisteredStateReply) in
                guard response.status == .successAlreadyExists || response.status == .successNewRegistration else {
                    return .failure(.networkError("Failed to register device: \(response.status)"))
                }
                return .success(response)
            }
        ).flatMap { response in
            Result<Ecliptix_Proto_AppDevice_ApplicationInstanceSettings, InternalValidationFailure>.Try({
                let appServerInstanceId = try Helpers.fromDataToGuid(response.uniqueID)
                
                var newSettings = Ecliptix_Proto_AppDevice_ApplicationInstanceSettings()
                newSettings.appInstanceID = settings.appInstanceID
                newSettings.deviceID = settings.deviceID
                newSettings.deviceType = settings.deviceType
                newSettings.systemDeviceIdentifier = appServerInstanceId.uuidString
                newSettings.serverPublicKey = response.serverPublicKey

                return newSettings
            }, errorMapper: {
                .internalServiceApi("Failed to process registration response", inner: $0)
            })
        }.flatMap { newSettings in
            AppSettingsService.shared.setSettings(newSettings)
                .mapInternalServiceApiFailure()
        }
    }
    
    func restoreSecrecyChannel(
        ecliptixSecrecyChannelState: Ecliptix_Proto_KeyMaterials_EcliptixSessionState,
        applicationInstanceSettings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings
    ) async -> Result<Bool, NetworkFailure> {
        return await self.sessionProvider.restoreSecrecyChannel(
            ecliptixSecrecyChannelState: ecliptixSecrecyChannelState,
            applicationInstanceSettings: applicationInstanceSettings
        )
    }
    
    public func recoverSession(
        settings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings,
        shouldBeRecovered: Bool
    ) async -> Result<Unit, InternalValidationFailure> {
        return await self.sessionProvider.establishSession(settings: settings, shouldBeRecovered: shouldBeRecovered)
            .mapNetworkFailure()
            .flatMapAsync { connectId in
                return await self.registerDeviceAsync(connectId: connectId, settings: settings)
            }
    }
}
