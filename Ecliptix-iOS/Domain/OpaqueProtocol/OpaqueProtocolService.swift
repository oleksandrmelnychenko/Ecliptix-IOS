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

        return OpaqueClientAuthentication.createSignInFinalizationRequest(
            phoneNumber: phoneNumber,
            passwordData: password,
            signInResponse: response,
            blind: blind,
            staticPublicKeyPoint: staticPoint,
            staticPublicKey: staticPublicKey,
            group: defaultGroup
        )
    }
    
    static func createOprfRequest(password: Data) -> Result<(oprfRequest: Data, blind: UnsafeMutablePointer<BIGNUM>), OpaqueFailure> {
        do {
            let group = getDefaultGroup()
            
            // 1. Генеруємо сліпий скаляр
            let generatedScalarResult = ECPointUtils.generateRandomScalar(group: group)
            guard case let .success(blind) = generatedScalarResult else {
                return .failure(try generatedScalarResult.unwrapErr())
            }
            
            // 2. Хешуємо пароль у точку
            guard case let .success(encodedPoint) = OpaqueCryptoUtilities.hashToPoint(password) else {
                return .failure(.pointDecodingFailed("Failed to hash password to EC point"))
            }
            
            let ctx = BN_CTX_new()!
            defer { BN_CTX_free(ctx) }
            
            // 3. Декодуємо EC_POINT з байтів
            guard case let .success(point) = ECPointUtils.decodeCompressedPoint(encodedPoint, group: group, ctx: ctx) else {
                return .failure(.pointDecodingFailed("Failed to decode EC point from bytes"))
            }
            defer { EC_POINT_free(point) }

            // 4. Помножити на сліпий скаляр
            guard let blindedPoint = EC_POINT_new(group) else {
                return .failure(.pointMultiplicationFailed("Failed to allocate blinded EC_POINT"))
            }
            defer { EC_POINT_free(blindedPoint) }

            guard EC_POINT_mul(group, blindedPoint, nil, point, blind, ctx) == 1 else {
                return .failure(.pointMultiplicationFailed("Failed to multiply point with blind"))
            }

            // 5. Стиснути до байтів
            let compressedResult = ECPointUtils.compressPoint(blindedPoint, group: group, ctx: ctx)
            guard case let .success(compressed) = compressedResult else {
                return .failure(try compressedResult.unwrapErr())
            }

            return .success((oprfRequest: compressed, blind: blind))
        } catch {
            return .failure(.invalidInput("Error during create oprf request", inner: error))
        }
    }

    public func verifyServerMacAndGetSessionKey(
        response: Ecliptix_Proto_Membership_OpaqueSignInFinalizeResponse,
        sessionKey: Data, serverMacKey: Data, transcriptHash: Data
    ) -> Result<Data, OpaqueFailure> {
        return OpaqueCryptoUtilities
            .createMac(key: serverMacKey, data: transcriptHash)
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
