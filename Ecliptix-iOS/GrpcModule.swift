//
//  GrpcModule.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 11.06.2025.
//

import GRPC
import NIOCore
import Foundation
import NIO

enum GrpcModule {
    static func configureServices() {
        let appSettins = AppSettings()
        ServiceLocator.shared.register(AppSettings.self, service: appSettins)
        
        let appInstanceInfo = AppInstanceInfo()
        ServiceLocator.shared.register(AppInstanceInfo.self, service: appInstanceInfo)
    }
    
    static func configureGrpcClients() {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        let channel = ClientConnection.insecure(group: group)
            .connect(host: "localhost", port: 5051)

        let appInstanceInfo = ServiceLocator.shared.resolve(AppInstanceInfo.self)
        
        // Interceptors
        let membershipInterceptorFactory = MembershipInterceptorFactory(
            appInstanceId: appInstanceInfo.appInstanceId,
            deviceId: appInstanceInfo.deviceId
        )
        
        let appDeviceInterceptorFactory = AppDeviceInterceptorFactory(
            appInstanceId: appInstanceInfo.appInstanceId,
            deviceId: appInstanceInfo.deviceId
        )
        
        // Clients
        let membershipClient = Ecliptix_Proto_Membership_MembershipServicesAsyncClient(
            channel: channel,
            interceptors: membershipInterceptorFactory
        )
        
        let appDeviceClient = Ecliptix_Proto_AppDevice_AppDeviceServiceActionsAsyncClient(
            channel: channel,
            interceptors: appDeviceInterceptorFactory
        )

        let callOptions = CallOptions()

        let authClient = Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient(
            channel: channel,
            defaultCallOptions: callOptions
        )
        
        let singleCallExecutor = SingleCallExecutor(
            membershipClient: membershipClient,
            appDeviceClient: appDeviceClient,
            authClient: authClient
        )

        let receiveStreamExecutor = ReceiveStreamExecutor(client: authClient)
        let keyExchangeExecutor = KeyExchangeExecutor(appDeviceServiceActionsClient: appDeviceClient)

        let serviceManager = NetworkServiceManager(
            singleCallExecutor: singleCallExecutor,
            receiveStreamExecutor: receiveStreamExecutor,
            keyExchangeExecutor: keyExchangeExecutor
        )

        let networkController = NetworkController(networkServiceManager: serviceManager)
        ServiceLocator.shared.register(NetworkController.self, service: networkController)
    }
}
