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

        let singleCallExecutor = SingleCallExecutor(
            membershipClient: clients.membership,
            appDeviceClient: clients.appDevice,
            authClient: clients.auth
        )

        let receiveStreamExecutor = ReceiveStreamExecutor(client: clients.auth)
        let keyExchangeExecutor = KeyExchangeExecutor(appDeviceServiceActionsClient: clients.appDevice)

        let manager = NetworkServiceManager(
            singleCallExecutor: singleCallExecutor,
            receiveStreamExecutor: receiveStreamExecutor,
            keyExchangeExecutor: keyExchangeExecutor
        )

        let controller = NetworkController(networkServiceManager: manager)
        ServiceLocator.shared.register(NetworkController.self, service: controller)
    }
}
