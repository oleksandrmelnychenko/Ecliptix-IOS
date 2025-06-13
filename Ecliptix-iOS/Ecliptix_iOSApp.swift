//
//  Ecliptix_iOSApp.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 09.06.2025.
//

import SwiftUI

@main
struct Ecliptix_iOSApp: App {
    private let defaultOneTimeKeyCount: UInt32 = 10
    private let networkController: NetworkController
    private let lock = NSLock()
    @State private var didInitialize = false
    
    @StateObject private var navigationService = NavigationService()
    
    init() {
        GrpcModule.configureServices()
        GrpcModule.configureGrpcClients()
        
        self.networkController = ServiceLocator.shared.resolve(NetworkController.self)
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationService.path) {
                WelcomeView(navigation: navigationService)
                    .environmentObject(navigationService)
                    .navigationDestination(for: AppRoute.self) { route in
                        ViewFactory.view(for: route, with: navigationService)
                    }
            }
//                .task {
//                    guard !didInitialize else { return }
//                    didInitialize = true
//                    await initializeApplicationAsync()
//                }
        }
    }
    
    private func initializeApplicationAsync() async {
        let (connectId, appDevice) = createEcliptixConnectionContext()
        
        let result = await networkController.dataCenterPubKeyExchange(connectId: connectId)
        
        if result.isErr {
            
        } else {
            await registerDeviceAsync(connectId: connectId, appDevice: appDevice, token: CancellationToken())
        }
    }

    private func createEcliptixConnectionContext() -> (UInt32, Ecliptix_Proto_AppDevice_AppDevice) {
        let appInstanceInfo = ServiceLocator.shared.resolve(AppInstanceInfo.self)
        var appDevice = Ecliptix_Proto_AppDevice_AppDevice()
        appDevice.appInstanceID = Utilities.guidToByteArray(appInstanceInfo.appInstanceId)
        appDevice.deviceID = Utilities.guidToByteArray(appInstanceInfo.deviceId)
        appDevice.deviceType = .mobile
        
        let connectId = Utilities.computeUniqueConnectId(appInstanceId: appInstanceInfo.appInstanceId, appDeviceId: appInstanceInfo.deviceId, contextType: .dataCenterEphemeralConnect)
        
        networkController.createEcliptixConnectionContext(
            connectId: connectId,
            oneTimeKeyCount: self.defaultOneTimeKeyCount,
            pubKeyExchangeType: .dataCenterEphemeralConnect)
        
        return (connectId, appDevice)
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
