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
    private let rpcMetaDataProvider: RpcMetaDataProviderProtocol
    
    init(rpcMetaDataProvider: RpcMetaDataProviderProtocol) {
        self.rpcMetaDataProvider = rpcMetaDataProvider
    }
    
    func makeEstablishAppDeviceSecrecyChannelInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_PubKeyExchange, Ecliptix_Proto_PubKeyExchange>] {
        return [RequestMetadataInterceptor<Ecliptix_Proto_PubKeyExchange, Ecliptix_Proto_PubKeyExchange>(
            rpcMetaDataProvider: rpcMetaDataProvider
        )]
    }
    
    func makeRestoreAppDeviceSecrecyChannelInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_RestoreSecrecyChannelRequest, Ecliptix_Proto_RestoreSecrecyChannelResponse>] {
        return [RequestMetadataInterceptor<Ecliptix_Proto_RestoreSecrecyChannelRequest, Ecliptix_Proto_RestoreSecrecyChannelResponse>(
            rpcMetaDataProvider: rpcMetaDataProvider
        )]
    }
    
    func makeRegisterDeviceAppIfNotExistInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        return [RequestMetadataInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>(
            rpcMetaDataProvider: rpcMetaDataProvider
        )]
    }
}
