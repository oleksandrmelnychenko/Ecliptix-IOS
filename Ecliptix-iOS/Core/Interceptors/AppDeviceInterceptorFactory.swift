//
//  AppDeviceInterceptorFactory.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 12.06.2025.
//


import Foundation
import GRPC
import NIOCore
import NIOHPACK

final class AppDeviceInterceptorFactory: Ecliptix_Proto_AppDevice_AppDeviceServiceActionsClientInterceptorFactoryProtocol {

    
    private let appInstanceId: UUID
    private let deviceId: UUID
    
    init(appInstanceId: UUID, deviceId: UUID) {
        self.appInstanceId = appInstanceId
        self.deviceId = deviceId
    }
    
    func makeEstablishAppDeviceEphemeralConnectInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_PubKeyExchange, Ecliptix_Proto_PubKeyExchange>] {
        return [RequestMetadataInterceptor<Ecliptix_Proto_PubKeyExchange, Ecliptix_Proto_PubKeyExchange>(
            appInstanceId: appInstanceId,
            deviceId: deviceId
        )]
    }
    
    func makeRegisterDeviceAppIfNotExistInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        return [RequestMetadataInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>(
            appInstanceId: appInstanceId,
            deviceId: deviceId
        )]
    }
}