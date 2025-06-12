//
//  ContentView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 09.06.2025.
//

import SwiftUI

struct ContentView: View {
    private let defaultOneTimeKeyCount: UInt32 = 10
    private let networkController = ServiceLocator.shared.resolve(NetworkController.self)
    private let lock = NSLock()

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
    
    private func initializeApplicationAsync() async {
        let (connectId, appDevice) = createEcliptixConnectionContext()
        
        let result = await networkController.dataCenterPubKeyExchange(connectId: connectId)
        
        if result.isErr {
            
        } else {
            await registerDeviceAsync(connectId: connectId, appDevice: appDevice, token: CancellationToken())
        }
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
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("Initialize Application") {
                Task {
                    await initializeApplicationAsync()
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
