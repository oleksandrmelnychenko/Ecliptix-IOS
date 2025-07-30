//
//  RequestBuilder.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 23.07.2025.
//

import Foundation
import CryptoKit
import OpenSSL

struct RequestBuilder {
    static func buildRegisterAppDeviceRequest(
        settings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings
    ) -> Result<Ecliptix_Proto_AppDevice_AppDevice, InternalValidationFailure> {
        var request = Ecliptix_Proto_AppDevice_AppDevice()
        
        request.appInstanceID = settings.appInstanceID
        request.deviceID = settings.deviceID
        request.deviceType = .mobile
        
        return .success(request)
    }
    
    static func buildValidationPhoneNumberRequest(
        networkProvider: NetworkProvider,
        phoneNumber: String
    ) -> Result<Ecliptix_Proto_Membership_ValidatePhoneNumberRequest, InternalValidationFailure> {
        
        if UUID(uuidString: phoneNumber) != nil {
            // Here we should log this!
            
            return .failure(.phoneNumberIsGuid(String(localized: "Phone number must not be a GUID.")))
        }
        
        return buildAppDeviceIdentifier(networkProvider: networkProvider)
            .map { deviceIdData in
                var request = Ecliptix_Proto_Membership_ValidatePhoneNumberRequest()
                
                request.phoneNumber = phoneNumber
                request.appDeviceIdentifier = deviceIdData

                return request
            }
    }
    
    static func buildInitiateVerificationRequest(
        networkProvider: NetworkProvider,
        phoneNumberIdentifier: Data,
        type: Ecliptix_Proto_Membership_InitiateVerificationRequest.TypeEnum
    ) -> Result<Ecliptix_Proto_Membership_InitiateVerificationRequest, InternalValidationFailure> {
        buildAppDeviceIdentifier(networkProvider: networkProvider)
            .map { deviceIdData in
                var request = Ecliptix_Proto_Membership_InitiateVerificationRequest()
                
                request.phoneNumberIdentifier = phoneNumberIdentifier
                request.appDeviceIdentifier = deviceIdData
                request.purpose = .registration
                request.type = type

                return request
            }
    }
    
    static func buildSendOtpRequest(
        networkProvider: NetworkProvider,
        otpCode: String
    ) -> Result<Ecliptix_Proto_Membership_VerifyCodeRequest, InternalValidationFailure> {
        buildAppDeviceIdentifier(networkProvider: networkProvider)
            .map { deviceIdData in
                var request = Ecliptix_Proto_Membership_VerifyCodeRequest()
                
                request.code = otpCode
                request.purpose = .registration
                request.appDeviceIdentifier = deviceIdData

                return request
            }
    }
    
    static func buildRegistrationInitRequest(
        passwordData: Data,
        oprfRequest: Data,
        passwordManager: PasswordManager,
        verificationSessionId: Data
    ) -> Result<Ecliptix_Proto_Membership_OprfRegistrationInitRequest, InternalValidationFailure> {
        
        return Result<Data, InternalValidationFailure>.success(passwordData)
            .flatMap { _ in
                
                guard let passwordString = String(data: passwordData, encoding: .utf8) else {
                    return .failure(.invalidValue("Password contains invalid characters for string conversion."))
                }

                return .success(passwordString)
            }
            .flatMap { passwordString in
                passwordManager.hashPassword(passwordString)
                    .mapEcliptixProtocolFailure()
                    .mapNetworkFailure()
            }
            .map { _ in
                var request = Ecliptix_Proto_Membership_OprfRegistrationInitRequest()
                request.membershipIdentifier = verificationSessionId
                request.peerOprf = oprfRequest
                return request
            }
    }
    
    static func buildRegistrationCompleteRequest(
        passwordData: Data,
        blind: UnsafePointer<BIGNUM>,
        response: Ecliptix_Proto_Membership_OprfRegistrationInitResponse
    ) -> Result<Ecliptix_Proto_Membership_OprfRegistrationCompleteRequest, InternalValidationFailure> {

        return Result<Data, InternalValidationFailure>.success(passwordData)
            .flatMap { passwordData in
                OpaqueProtocolService.createRegistrationRecord(
                    password: passwordData,
                    oprfResponse: response.peerOprf,
                    blind: blind
                )
                .mapError { .internalServiceApi("Failed to create registration record", inner: $0) }
            }
            .map { envelope in
                var request = Ecliptix_Proto_Membership_OprfRegistrationCompleteRequest()
                request.membershipIdentifier = response.membership.uniqueIdentifier
                request.peerRegistrationRecord = envelope
                return request
            }
    }
    
    static func buildRecoverySecureKeyInitRequest(
        passwordData: Data,
        oprfRequest: Data,
        passwordManager: PasswordManager,
        verificationSessionId: Data
    ) -> Result<Ecliptix_Proto_Membership_OprfRecoverySecureKeyInitRequest, InternalValidationFailure> {
        return Result<String, InternalValidationFailure>.Try({
            guard let passwordString = String(data: passwordData, encoding: .utf8) else {
                throw InternalValidationFailure.invalidValue("Password contains invalid characters for string conversion.")
            }
            return passwordString
        }, errorMapper: { error in
            if let failure = error as? InternalValidationFailure {
                return failure
            } else {
                return .internalServiceApi("Failed to convert password to string", inner: error)
            }
        })
        .flatMap { passwordString in
            passwordManager.hashPassword(passwordString)
                .mapEcliptixProtocolFailure()
                .mapNetworkFailure()
        }
        .map { _ in
            var request = Ecliptix_Proto_Membership_OprfRecoverySecureKeyInitRequest()
            request.membershipIdentifier = verificationSessionId
            request.peerOprf = oprfRequest
            return request
        }
    }
    
    static func buildRecoverySecureKeyCompleteRequest(
        passwordData: Data,
        response: Ecliptix_Proto_Membership_OprfRecoverySecureKeyInitResponse
    ) -> Result<Ecliptix_Proto_Membership_OprfRecoverySecretKeyCompleteRequest, InternalValidationFailure> {
        
        return Result<Data, InternalValidationFailure>.success(passwordData)
            .flatMap { _ in
                OpaqueProtocolService.createOprfRequest(password: passwordData)
                    .mapOpaqueFailure()
            }
            .flatMap { oprfData in
                OpaqueProtocolService.createRegistrationRecord(
                    password: passwordData,
                    oprfResponse: response.peerOprf,
                    blind: oprfData.blind)
                .mapOpaqueFailure()
            }
            .map { envelope in
                var request = Ecliptix_Proto_Membership_OprfRecoverySecretKeyCompleteRequest()
                
                request.membershipIdentifier = response.membership.uniqueIdentifier
                request.peerRecoveryRecord = envelope
                
                return request
            }
    }
    
    static func buildSignInInitRequest(
        passwordData: Data,
        oprfRequest: Data,
        phoneNumber: String
    ) -> Result<Ecliptix_Proto_Membership_OpaqueSignInInitRequest, InternalValidationFailure> {
        var request = Ecliptix_Proto_Membership_OpaqueSignInInitRequest()
        
        request.phoneNumber = phoneNumber
        request.peerOprf = oprfRequest
        
        return .success(request)
    }
    
    static func buildSignInCompleteRequest(
        phoneNumber: String,
        clientEphemeralPublicKey: Data,
        clientMacKey: Data,
        transcriptHash: Data,
        response: Ecliptix_Proto_Membership_OpaqueSignInInitResponse
    ) -> Result<Ecliptix_Proto_Membership_OpaqueSignInFinalizeRequest, InternalValidationFailure> {
        return EVPCryptoUtils.createMac(key: clientMacKey, data: transcriptHash)
            .mapOpaqueFailure()
            .map { clientMac in
                var request = Ecliptix_Proto_Membership_OpaqueSignInFinalizeRequest()
                
                request.phoneNumber = phoneNumber
                request.clientEphemeralPublicKey = clientEphemeralPublicKey
                request.clientMac = clientMac
                request.serverStateToken = response.serverStateToken
                
                return request
            }
    }
    
    // MARK: - Private helpers
    private static func buildAppDeviceIdentifier(networkProvider: NetworkProvider) -> Result<Data, InternalValidationFailure> {
        return ViewModelBase.systemDeviceIdentifier()
            .mapError { error in
                // Here we should log this!
                
                return .deviceIdUnavailable(String(localized: "Device ID could not be retrieved."))
            }
            .flatMap { systemId in
                guard let uuid = UUID(uuidString: systemId) else {
                    // Here we should log this!
                    
                    return .failure(.invalidValue(String(localized: "Device ID is not a valid UUID.")))
                }

                let deviceIdData = withUnsafeBytes(of: uuid.uuid) { Data($0) }
                return .success(deviceIdData)
            }
    }
}
