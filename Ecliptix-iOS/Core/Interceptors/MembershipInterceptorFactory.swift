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
    private let appInstanceId: UUID
    private let deviceId: UUID

    init(appInstanceId: UUID, deviceId: UUID) {
        self.appInstanceId = appInstanceId
        self.deviceId = deviceId
    }

    func makeUpdateMembershipWithSecureKeyInterceptors() -> [ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        return [RequestMetadataInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>(
            appInstanceId: appInstanceId,
            deviceId: deviceId
        )]
    }

    func makeSignInMembershipInterceptors() -> [ClientInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>] {
        return [RequestMetadataInterceptor<Ecliptix_Proto_CipherPayload, Ecliptix_Proto_CipherPayload>(
            appInstanceId: appInstanceId,
            deviceId: deviceId
        )]
    }
}