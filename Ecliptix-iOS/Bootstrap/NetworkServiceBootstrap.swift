//
//  NetworkServiceBootstrap.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 01.07.2025.
//

import GRPC

enum NetworkServiceBootstrap {
    static func setupNetworkController(channel: ClientConnection) {
        let clients = GrpcClientFactory.makeClients(channel: channel)

        let unaryRpcService = UnaryRpcService(
            membershipClient: clients.membership,
            appDeviceClient: clients.appDevice,
            authClient: clients.auth
        )

        let receiveStreamExecutor = ReceiveStreamRpcService(client: clients.auth)
        let keyExchangeExecutor = SecrecyChannelRpcService(appDeviceServiceActionsClient: clients.appDevice)

        let manager = RpcServiceManager(
            unaryRpcService: unaryRpcService,
            receiveStreamExecutor: receiveStreamExecutor,
            secrecyChannelRpcService: keyExchangeExecutor
        )

        
        
        let secureStoreProvider = ServiceLocator.shared.resolve(SecureStorageProviderProtocol.self)
        let rpcMetaDataProvider = ServiceLocator.shared.resolve(RpcMetaDataProviderProtocol.self)
        let controller = NetworkProvider(
            secureStorageProvider: secureStoreProvider,
            rpcMetaDataProvider: rpcMetaDataProvider,
            rpcServiceManager: manager)
        ServiceLocator.shared.register(NetworkProviderProtocol.self, service: controller)
        ServiceLocator.shared.register(NetworkProvider.self, service: controller)
    }
}
