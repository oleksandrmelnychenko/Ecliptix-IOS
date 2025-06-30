//
//  SessionExecutor.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 19.06.2025.
//

import Foundation

final class EstablishConnectionExecutor {
    private let defaultOneTimeKeyCount: UInt32 = 10
    private let networkController: NetworkController
    private let lock = NSLock()
    
    init() {
        self.networkController = ServiceLocator.shared.resolve(NetworkController.self)
    }
    
    public func initializeApplicationAsync() async {
        let (connectId, appDevice) = createEcliptixConnectionContext()
        
        let result = await networkController.dataCenterPubKeyExchange(connectId: connectId)
        
        if result.isErr {
            
        } else {
            await registerDeviceAsync(connectId: connectId, appDevice: appDevice, token: CancellationToken())
        }
    }
    
    public func reEstablishConnectionAsync() async {
        let connectId = computeConnectId()
        let appDevice = computeAppDeviceId()
        let result = await networkController.dataCenterPubKeyExchange(connectId: connectId)
        
        if result.isErr {
            
        } else {
            await registerDeviceAsync(connectId: connectId, appDevice: appDevice, token: CancellationToken())
        }
    }

    private func createEcliptixConnectionContext() -> (UInt32, Ecliptix_Proto_AppDevice_AppDevice) {
        let connectId = computeConnectId()
        let appDevice = computeAppDeviceId()
        
        networkController.createEcliptixConnectionContext(
            connectId: connectId,
            oneTimeKeyCount: self.defaultOneTimeKeyCount,
            pubKeyExchangeType: .dataCenterEphemeralConnect)
        
        return (connectId, appDevice)
    }
    
    private func computeConnectId() -> UInt32 {
        let appInstanceInfo = ServiceLocator.shared.resolve(AppInstanceInfo.self)

        let connectId = Utilities.computeUniqueConnectId(appInstanceId: appInstanceInfo.appInstanceId, appDeviceId: appInstanceInfo.deviceId, contextType: .dataCenterEphemeralConnect)
        
        return connectId
    }
    
    private func computeAppDeviceId() -> Ecliptix_Proto_AppDevice_AppDevice {
        let appInstanceInfo = ServiceLocator.shared.resolve(AppInstanceInfo.self)
        var appDevice = Ecliptix_Proto_AppDevice_AppDevice()
        appDevice.appInstanceID = Utilities.guidToByteArray(appInstanceInfo.appInstanceId)
        appDevice.deviceID = Utilities.guidToByteArray(appInstanceInfo.deviceId)
        appDevice.deviceType = .mobile
        
        return appDevice
    }
    
    private func registerDeviceAsync(connectId: UInt32, appDevice: Ecliptix_Proto_AppDevice_AppDevice, token: CancellationToken) async {
        
        do {
            _ = try await networkController.executeServiceAction(
                connectId: connectId,
                serviceAction: .registerAppDevice,
                plainBuffer: appDevice.serializedData(),
                flowType: .single,
                onSuccessCallback: { decryptedPayload in
                    do {
                        let reply = try Utilities.parseFromBytes(Ecliptix_Proto_AppDevice_AppDeviceRegisteredStateReply.self, data: decryptedPayload)
                        
                        let appServerInstanceId = try Utilities.fromByteStringToGuid(reply.uniqueID)
                        
                        let appInstanceID = ServiceLocator.shared.resolve(AppInstanceInfo.self)
                        
                        await appInstanceID.setSystemDeviceIdentifier(appServerInstanceId)
                        await appInstanceID.setServerPublicKey(reply.serverPublicKey)
                        
                        return .success(.value)
                    } catch {
                        return .failure(.generic("Failed to parse reply", inner: error))
                    }
            }, token: token)
        } catch {
            debugPrint("Error in registerDeviceAsync: \(error.localizedDescription)")
        }
    }
}
