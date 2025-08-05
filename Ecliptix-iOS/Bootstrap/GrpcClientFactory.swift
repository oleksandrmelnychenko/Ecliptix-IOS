//
//  GrpcClientFactory.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 01.07.2025.
//

import GRPC
import NIO

struct GrpcClientFactory {
    static func createChannel() -> ClientConnection {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        return ClientConnection.insecure(group: group)
            .connect(host: "localhost", port: 5051)
    }

    static func makeClients(channel: ClientConnection) -> (
        membership: Ecliptix_Proto_Membership_MembershipServicesAsyncClient,
        auth: Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient,
        appDevice: Ecliptix_Proto_AppDevice_AppDeviceServiceActionsAsyncClient
    ) {
        let rpcMetaDataProvider = try! ServiceLocator.shared.resolve(RpcMetaDataProviderProtocol.self)
        
        let membershipClient = Ecliptix_Proto_Membership_MembershipServicesAsyncClient(
            channel: channel,
            interceptors: MembershipInterceptorFactory(rpcMetaDataProvider: rpcMetaDataProvider)
        )

        let authClient = Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient(
            channel: channel,
            interceptors: AuthInterceptorFactory(rpcMetaDataProvider: rpcMetaDataProvider)
        )

        let appDeviceClient = Ecliptix_Proto_AppDevice_AppDeviceServiceActionsAsyncClient(
            channel: channel,
            interceptors: AppDeviceInterceptorFactory(rpcMetaDataProvider: rpcMetaDataProvider)
        )

        return (membershipClient, authClient, appDeviceClient)
    }
}
