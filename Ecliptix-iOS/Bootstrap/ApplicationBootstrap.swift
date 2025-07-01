//
//  GrpcModule.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 11.06.2025.
//

enum ApplicationBootstrap {
    static func configure() {
        AppServiceConfigurator.registerCoreServices()
        
        let channel = GrpcClientFactory.createChannel()
        NetworkServiceBootstrap.setupNetworkController(channel: channel)
    }
}
