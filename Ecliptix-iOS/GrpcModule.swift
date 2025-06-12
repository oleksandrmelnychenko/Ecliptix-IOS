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
    static func registerAll() {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        let channel = ClientConnection.insecure(group: group)
            .connect(host: "localhost", port: 5051)

        let appInstanceInfo = AppInstanceInfo()
        
        // Interceptors
        let membershipInterceptorFactory = MembershipInterceptorFactory(
            appInstanceId: appInstanceInfo.appInstanceId,
            deviceId: appInstanceInfo.deviceId
        )
        
        let appDeviceInterceptorFactory = AppDeviceInterceptorFactory(
            appInstanceId: appInstanceInfo.appInstanceId,
            deviceId: appInstanceInfo.deviceId
        )
        
//        let authInterceptorFactory = AuthInterceptorFactory(
//            appInstanceId: appInstanceInfo.appInstanceId,
//            deviceId: appInstanceInfo.deviceId
//        )
        
        // Clients
        let membershipClient = Ecliptix_Proto_Membership_MembershipServicesAsyncClient(
            channel: channel,
            interceptors: membershipInterceptorFactory
        )
        
        let appDeviceClient = Ecliptix_Proto_AppDevice_AppDeviceServiceActionsAsyncClient(
            channel: channel,
            interceptors: appDeviceInterceptorFactory
        )
        
//        let authClient = Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient(
//            channel: channel,
//            interceptors: authInterceptorFactory
//        )

        let callOptions = CallOptions()

        let authClient = Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient(
            channel: channel,
            defaultCallOptions: callOptions
        )
        
//        let appDeviceClient = Ecliptix_Proto_AppDevice_AppDeviceServiceActionsAsyncClient(
//            channel: channel,
//            interceptors: appDeviceInterceptorFactory
//        )
        
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
        ServiceLocator.shared.register(AppInstanceInfo.self, service: appInstanceInfo)
    }
}
