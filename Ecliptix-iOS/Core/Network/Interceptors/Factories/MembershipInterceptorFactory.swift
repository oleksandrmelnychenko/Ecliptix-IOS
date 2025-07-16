//
//  MembershipInterceptorFactory.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 12.06.2025.
//


import Foundation
import GRPC
import NIOCore
import NIOHPACK

final class MembershipInterceptorFactory: Ecliptix_Proto_Membership_MembershipServicesClientInterceptorFactoryProtocol {
    private let rpcMetaDataProvider: RpcMetaDataProviderProtocol

    init(rpcMetaDataProvider: RpcMetaDataProviderProtocol) {
        self.rpcMetaDataProvider = rpcMetaDataProvider
    }
    
    func makeOpaqueRegistrationInitRequestInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        [RequestMetadataInterceptor(rpcMetaDataProvider: self.rpcMetaDataProvider)]
    }
    
    func makeOpaqueRegistrationCompleteRequestInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        [RequestMetadataInterceptor(rpcMetaDataProvider: self.rpcMetaDataProvider)]
    }
    
    func makeOpaqueSignInInitRequestInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        [RequestMetadataInterceptor(rpcMetaDataProvider: self.rpcMetaDataProvider)]
    }
    
    func makeOpaqueSignInCompleteRequestInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        [RequestMetadataInterceptor(rpcMetaDataProvider: self.rpcMetaDataProvider)]
    }
    
    func makeOpaqueRecoverySecretKeyInitRequestInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        [RequestMetadataInterceptor(rpcMetaDataProvider: self.rpcMetaDataProvider)]
    }
    
    func makeOpaqueRecoverySecretKeyCompleteRequestInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        [RequestMetadataInterceptor(rpcMetaDataProvider: self.rpcMetaDataProvider)]
    }
}
