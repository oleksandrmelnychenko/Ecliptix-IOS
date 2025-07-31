//
//  OpaqueProtocolService.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 26.06.2025.
//

import Foundation
import CryptoKit
import OpenSSL


class OpaqueProtocolService {
    private let staticPublicKey: Data
    private let staticPublicKeyPoint: OpaquePointer?
    private let defaultGroup: OpaquePointer

    init(staticPublicKey: Data) {
        self.staticPublicKey = staticPublicKey

        let group = Self.getDefaultGroup()
        self.defaultGroup = group

        let ctx = BN_CTX_new()
        if let ctx {
            defer { BN_CTX_free(ctx) }

            let decodeResult = ECPointUtils.decodeCompressedPoint(staticPublicKey, group: group, ctx: ctx)
            switch decodeResult {
            case let .success(point):
                self.staticPublicKeyPoint = point
            case .failure:
                self.staticPublicKeyPoint = nil
            }
        } else {
            self.staticPublicKeyPoint = nil
        }
    }
    
    deinit {
        if let point = staticPublicKeyPoint {
            EC_POINT_free(point)
        }
    }
    
    static func createRegistrationRecord(password: Data, oprfResponse: Data, blind: UnsafePointer<BIGNUM>) -> Result<Data, OpaqueFailure> {
        return OpaqueClientRegistration.createRegistrationRecord(
            password: password,
            oprfResponse: oprfResponse,
            blind: blind,
            group: Self.getDefaultGroup()
        )
    }

    func createSignInFinalizationRequest(
        phoneNumber: String,
        password: Data,
        response: Ecliptix_Proto_Membership_OpaqueSignInInitResponse,
        blind: UnsafePointer<BIGNUM>
    ) -> Result<SignInFinalizationContext, OpaqueFailure> {
        guard let staticPoint = staticPublicKeyPoint else {
            return .failure(.invalidInput("Static public key point is nil"))
        }

        return OpaqueClientAuthentication.createSignInFinalizationContext(
            phoneNumber: phoneNumber,
            passwordData: password,
            signInResponse: response,
            blind: blind,
            staticPublicKeyPoint: staticPoint,
            staticPublicKey: staticPublicKey,
            group: defaultGroup
        )
    }
    
    static func createOprfRequest(password: Data) -> Result<OprfData, OpaqueFailure> {
        let group = getDefaultGroup()
        
        return BigNumUtils.generateRandomScalar(group: group)
            .flatMap { blind in
                OpaqueHashingUtils.hashToPoint(password, group: group)
                    .flatMap { encodedPoint in
                        ECPointUtils.withBnCtx { ctx in
                            ECPointUtils.decodeCompressedPoint(encodedPoint, group: group, ctx: ctx)
                                .flatMap { point in
                                    defer { EC_POINT_free(point) }

                                    return ECPublicKeyUtils.pointMul(group: group, point: point, scalar: blind, ctx: ctx)
                                        .flatMap { blindedPoint in
                                            ECPublicKeyUtils.compressPoint(blindedPoint, group: group, ctx: ctx)
                                               .map { compressed in
                                                   OprfData(oprfRequest: compressed, blind: blind)
                                               }
                                        }
                                }
                        }
                    }
            }
    }


    public func verifyServerMacAndGetSessionKey(
        response: Ecliptix_Proto_Membership_OpaqueSignInFinalizeResponse,
        sessionKey: Data, serverMacKey: Data, transcriptHash: Data
    ) -> Result<Data, OpaqueFailure> {
        return EVPCryptoUtils.createMac(key: serverMacKey, data: transcriptHash)
            .flatMap { expectedServerMac in
                response.serverMac == expectedServerMac
                    ? .success(sessionKey)
                    : .failure(.macVerificationFailed("Server MAC verification failed."))
            }
    }
    
    private static var cachedGroup: OpaquePointer = {
        EC_GROUP_new_by_curve_name(NID_X9_62_prime256v1)!
    }()
    
    private static func getDefaultGroup() -> OpaquePointer {
        return cachedGroup
    }
}
