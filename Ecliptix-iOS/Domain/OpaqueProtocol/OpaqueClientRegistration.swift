//
//  OpaqueClientRegistration.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 01.07.2025.
//

import Foundation
import OpenSSL

enum OpaqueClientRegistration {
    static func createRegistrationRecord(
        password: Data,
        oprfResponse: Data,
        blind: UnsafePointer<BIGNUM>,
        group: OpaquePointer
    ) -> Result<Data, OpaqueFailure> {
        do {
            // Step 1: Recover OPRF Key
            guard case let .success(oprfKey) = OpaqueCryptoUtilities.recoverOprfKey(oprfResponse: oprfResponse, blind: blind, group: group) else {
                return .failure(.invalidInput("Failed to recover OPRF key"))
            }

            // Step 2: Derive credential key
            let credentialKeyResult = OpaqueCryptoUtilities.deriveKey(
                ikm: oprfKey,
                salt: nil,
                info: OpaqueConstants.credentialKeyInfo,
                outputLength: OpaqueConstants.defaultKeyLength
            )
            guard case let .success(credentialKey) = credentialKeyResult else {
                return .failure(try credentialKeyResult.unwrapErr())
            }

            // Step 3: Generate key pair
            let generatedKeyPairResult = ECPointUtils.generateKeyPair(group: group)
            guard case let .success((privBN, pubPoint)) = generatedKeyPairResult else {
                return .failure(try generatedKeyPairResult.unwrapErr())
            }
            defer {
                BN_free(privBN)
                EC_POINT_free(pubPoint)
            }

            let ctx = BN_CTX_new()
            guard let ctx else {
                return .failure(.invalidInput("Failed to allocate BN_CTX"))
            }
            defer { BN_CTX_free(ctx) }
            
            // Step 4: Serialize keys
            guard case let .success(clientPrivateKeyBytes) = exportPrivateKey(privBN),
                  case let .success(clientPublicKeyBytes) = ECPointUtils.compressPoint(pubPoint, group: group, ctx: ctx) else {
                return .failure(.pointCompressionFailed("Key export failed"))
            }

            // Step 5: Encrypt private key (envelope)
            let envelopeResult = SymmetricCryptoService.encrypt(
                plaintext: clientPrivateKeyBytes,
                key: credentialKey,
                associatedData: password
            )
            guard case let .success(envelope) = envelopeResult else {
                return .failure(try envelopeResult.unwrapErr())
            }

            // Step 6: Compose registration record
            var registrationRecord = Data()
            registrationRecord.append(clientPublicKeyBytes)
            registrationRecord.append(envelope)

            return .success(registrationRecord)
        } catch {
            return .failure(.invalidInput("Error during create registration record", inner: error))
        }
    }
    
    private static func exportPrivateKey(_ bn: UnsafeMutablePointer<BIGNUM>) -> Result<Data, OpaqueFailure> {
        let length = (BN_num_bits(bn) + 7) / 8
        var buffer = [UInt8](repeating: 0, count: Int(length))
        BN_bn2bin(bn, &buffer)
        return .success(Data(buffer))
    }
}
