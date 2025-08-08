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
    private let cancellationToken: CancellationToken?
    
    init(rpcMetaDataProvider: RpcMetaDataProviderProtocol, cancellationToken: CancellationToken? = nil) {
        self.rpcMetaDataProvider = rpcMetaDataProvider
        self.cancellationToken = cancellationToken
    }
    
    func makeInitiateVerificationInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        return [
            RequestMetadataInterceptor(rpcMetaDataProvider: self.rpcMetaDataProvider),
            CancellationInterceptor(cancellationToken: cancellationToken ?? CancellationToken())
        ]
    }
    
    func makeVerifyOtpInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        [RequestMetadataInterceptor(rpcMetaDataProvider: self.rpcMetaDataProvider)]
    }
    
    func makeValidatePhoneNumberInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        [RequestMetadataInterceptor(rpcMetaDataProvider: self.rpcMetaDataProvider)]
    }
    
    func makeRecoverySecretKeyPhoneVerificationInterceptors() -> [GRPC.ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        [RequestMetadataInterceptor(rpcMetaDataProvider: self.rpcMetaDataProvider)]
    }
}
