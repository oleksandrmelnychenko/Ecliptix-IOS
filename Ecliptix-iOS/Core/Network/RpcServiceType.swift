//
//  RcpServiceAction.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

public enum RpcServiceType {
    case establishSecrecyChannel
    case restoreSecrecyChannel
    case registerAppDevice
    case validatePhoneNumber
    case verifyOtp
    case initiateVerification
    case opaqueRegistrationInit
    case opaqueRegistrationComplete
    case opaqueSignInInit
    case opaqueSignInComplete
}
