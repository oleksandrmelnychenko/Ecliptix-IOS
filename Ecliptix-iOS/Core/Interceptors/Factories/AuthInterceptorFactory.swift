//
//  AuthInterceptorFactory.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 12.06.2025.
//


import Foundation
import GRPC
import NIOCore
import NIOHPACK

final class AuthInterceptorFactory: Ecliptix_Proto_Membership_AuthVerificationServicesClientInterceptorFactoryProtocol {
    private let rpcMetaDataProvider: RpcMetaDataProviderProtocol
    
    init(rpcMetaDataProvider: RpcMetaDataProviderProtocol) {
        self.rpcMetaDataProvider = rpcMetaDataProvider
    }
    
    func makeInitiateVerificationInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        return [RequestMetadataInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>(
            rpcMetaDataProvider: rpcMetaDataProvider
        )]
    }
    
    func makeVerifyOtpInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        return [RequestMetadataInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>(
            rpcMetaDataProvider: rpcMetaDataProvider
        )]
    }
    
    func makeValidatePhoneNumberInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        return [RequestMetadataInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>(
            rpcMetaDataProvider: rpcMetaDataProvider
        )]
    }
}
