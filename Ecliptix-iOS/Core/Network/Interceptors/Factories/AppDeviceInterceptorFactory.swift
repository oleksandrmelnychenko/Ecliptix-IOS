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
        [RequestMetadataInterceptor(rpcMetaDataProvider: self.rpcMetaDataProvider)]
    }
    
    func makeRestoreAppDeviceSecrecyChannelInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_RestoreSecrecyChannelRequest, Ecliptix_Proto_RestoreSecrecyChannelResponse>] {
        [RequestMetadataInterceptor(rpcMetaDataProvider: self.rpcMetaDataProvider)]
    }
    
    func makeRegisterDeviceAppIfNotExistInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        [RequestMetadataInterceptor(rpcMetaDataProvider: self.rpcMetaDataProvider)]
    }
}
