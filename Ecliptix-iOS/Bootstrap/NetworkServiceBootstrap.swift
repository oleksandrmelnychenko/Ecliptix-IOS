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
            secrecyChannelRpcService: keyExchangeExecutor,
            networkEvents: try! ServiceLocator.shared.resolve(NetworkEventsProtocol.self),
            systemEvents: try! ServiceLocator.shared.resolve(SystemEventsProtocol.self))

        
        
        let secureStoreProvider = try! ServiceLocator.shared.resolve(SecureStorageProviderProtocol.self)
        let rpcMetaDataProvider = try! ServiceLocator.shared.resolve(RpcMetaDataProviderProtocol.self)
        
        let sessionProvider = SessionProvider(
            rpcMetaDataProvider: rpcMetaDataProvider,
            secureStorageProvider: secureStoreProvider,
            rpcServiceManager: manager,
            networkEvents: try! ServiceLocator.shared.resolve(NetworkEventsProtocol.self),
            systemEvents: try! ServiceLocator.shared.resolve(SystemEventsProtocol.self))
        
        let requestExecutor = RequestExecutor(rpcServiceManager: manager)
        
        let networkProvider = NetworkProvider(
            requestExecutor: requestExecutor,
            sessionProvider: sessionProvider,
            secureStorageProvider: secureStoreProvider
        )
        
        ServiceLocator.shared.register(NetworkProvider.self, service: networkProvider)
    }
}
