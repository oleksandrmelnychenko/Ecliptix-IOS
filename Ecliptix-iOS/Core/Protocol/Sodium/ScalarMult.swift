//
//  ScalarMult.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 04.06.2025.
//


import Foundation
import Sodium
import Clibsodium

public enum ScalarMult {
    static func base(_ privateKey: inout Data) throws -> Data {
        guard privateKey.count == 32 else {
            throw EcliptixProtocolFailure.deriveKey("Private key must be 32 bytes.")
        }

        var output = Data(repeating: 0, count: 32)

        let result = output.withUnsafeMutableBytes { outputPtr in
            privateKey.withUnsafeBytes { privateKeyPtr in
                crypto_scalarmult_curve25519_base(
                    outputPtr.bindMemory(to: UInt8.self).baseAddress!,
                    privateKeyPtr.bindMemory(to: UInt8.self).baseAddress!
                )
            }
        }

        guard result == 0 else {
            throw EcliptixProtocolFailure.deriveKey("crypto_scalarmult_curve25519_base failed with result \(result)")
        }

        return output
    }
    
    static func mult(_ privateKey: Data, _ publicKey: Data) throws -> Data {
        guard privateKey.count == 32 else {
            throw EcliptixProtocolFailure.deriveKey("Private key must be 32 bytes.")
        }
        guard publicKey.count == 32 else {
            throw EcliptixProtocolFailure.deriveKey("Public key must be 32 bytes.")
        }

        var output = Data(repeating: 0, count: 32)
        var privateKeyCopy = privateKey
        var publicKeyCopy = publicKey

        let result = output.withUnsafeMutableBytes { outputPtr -> Int32 in
            guard let outputBase = outputPtr.bindMemory(to: UInt8.self).baseAddress else {
                return -1
            }
            return privateKeyCopy.withUnsafeBytes { privKeyPtr -> Int32 in
                guard let privBase = privKeyPtr.bindMemory(to: UInt8.self).baseAddress else {
                    return -1
                }
                return publicKeyCopy.withUnsafeBytes { pubKeyPtr -> Int32 in
                    guard let pubBase = pubKeyPtr.bindMemory(to: UInt8.self).baseAddress else {
                        return -1
                    }
                    return crypto_scalarmult_curve25519(outputBase, privBase, pubBase)
                }
            }
        }

        guard result == 0 else {
            throw EcliptixProtocolFailure.deriveKey("crypto_scalarmult_curve25519 failed with result \(result)")
        }

        return output
    }

}
