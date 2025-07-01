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
            let credentialKey = OpaqueCryptoUtilities.deriveKey(
                ikm: oprfKey,
                salt: nil,
                info: OpaqueConstants.credentialKeyInfo,
                outputLength: OpaqueConstants.defaultKeyLength
            )

            // Step 3: Generate key pair
            guard let (privBN, pubPoint) = OpaqueCryptoUtilities.generateKeyPair(group: group) else {
                return .failure(.invalidInput("Failed to generate EC key pair"))
            }
            defer {
                BN_free(privBN)
                EC_POINT_free(pubPoint)
            }

            // Step 4: Serialize keys
            guard case let .success(clientPrivateKeyBytes) = exportPrivateKey(privBN),
                  case let .success(clientPublicKeyBytes) = exportCompressedPublicKey(pubPoint, group: group) else {
                return .failure(.pointCompressionFailed("Key export failed"))
            }

            // Step 5: Encrypt private key (envelope)
            let envelopeResult = OpaqueCryptoUtilities.encrypt(
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

    private static func exportCompressedPublicKey(_ point: OpaquePointer, group: OpaquePointer) -> Result<Data, OpaqueFailure> {
        var output = Data(repeating: 0, count: 33)
        let written = output.withUnsafeMutableBytes {
            EC_POINT_point2oct(group, point, POINT_CONVERSION_COMPRESSED,
                               $0.baseAddress?.assumingMemoryBound(to: UInt8.self), 33, nil)
        }

        guard written == 33 else {
            return .failure(.pointCompressionFailed("Compressed key must be 33 bytes"))
        }

        return .success(output)
    }
}
