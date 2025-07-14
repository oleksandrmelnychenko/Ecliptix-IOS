//
//  OneTimePreKeyLocal.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 23.05.2025.
//

import Foundation
import Sodium
import Clibsodium

public struct OneTimePreKeyLocal {
    public let preKeyId: UInt32
    public let privateKeyHandle: SodiumSecureMemoryHandle
    public let publicKey: Data

    private init(preKeyId: UInt32, privateKeyHandle: SodiumSecureMemoryHandle, publicKey: Data) {
        self.preKeyId = preKeyId
        self.privateKeyHandle = privateKeyHandle
        self.publicKey = publicKey
    }
    
    public static func createFromParts(preKeyId: UInt32, privateKeyHandle: SodiumSecureMemoryHandle, publicKey: Data) -> OneTimePreKeyLocal {
        return OneTimePreKeyLocal(preKeyId: preKeyId, privateKeyHandle: privateKeyHandle, publicKey: publicKey)
    }

    public static func generate(preKeyId: UInt32) -> Result<OneTimePreKeyLocal, EcliptixProtocolFailure> {
        var securePrivateKey: SodiumSecureMemoryHandle? = nil
        var tempPrivateKeyBytes: Data? = nil
        var tempPrivKeyCopy: Data? = nil
        
        do {
            let allocResult = SodiumSecureMemoryHandle.allocate(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
            if allocResult.isErr {
                return .failure(try allocResult.unwrapErr())
            }
            securePrivateKey = try allocResult.unwrap()
            
            var tempPrivateKeyBytes: Data?
            if let bytes = Sodium().randomBytes.buf(length: Constants.x25519PrivateKeySize) {
                tempPrivateKeyBytes = Data(bytes)
            } else {
                throw EcliptixProtocolFailure.generic("Failed to generate random bytes")
            }

            let writeResult = tempPrivateKeyBytes!.withUnsafeBytes { bufferPointer in
                securePrivateKey!.write(data: bufferPointer).mapSodiumFailure()
            }
            if writeResult.isErr {
                securePrivateKey?.dispose()
                _ = SodiumInterop.secureWipe(&tempPrivateKeyBytes)
                return .failure(try writeResult.unwrapErr())
            }
            
            _ = SodiumInterop.secureWipe(&tempPrivateKeyBytes)
            tempPrivateKeyBytes = nil
            
            tempPrivKeyCopy = Data(count: Constants.x25519PrivateKeySize)
            let readResult = tempPrivKeyCopy!.withUnsafeMutableBytes { bufferPointer in
                securePrivateKey!.read(into: bufferPointer).mapSodiumFailure()
            }
            if readResult.isErr {
                securePrivateKey?.dispose()
                _ = SodiumInterop.secureWipe(&tempPrivKeyCopy)
                return .failure(try readResult.unwrapErr())
            }
            
            let deriveResult = Result<Data, EcliptixProtocolFailure>.Try {
                return try ScalarMult.base(&tempPrivKeyCopy!)
            }.mapError { error in
                return EcliptixProtocolFailure.deriveKey("Failed to derive public key for OPK ID \(preKeyId)", inner: error)
            }
            
            _ = SodiumInterop.secureWipe(&tempPrivKeyCopy)
            tempPrivKeyCopy = nil
            
            if deriveResult.isErr {
                securePrivateKey?.dispose()
                return .failure(try deriveResult.unwrapErr())
            }
            
            var publicKeyBytes = try deriveResult.unwrap()
            
            if publicKeyBytes.count != Constants.x25519PublicKeySize {
                securePrivateKey?.dispose()
                _ = SodiumInterop.secureWipe(&publicKeyBytes)
                return .failure(.deriveKey("Derived public key for OPK ID \(preKeyId) has incorrect size (\(publicKeyBytes.count))."))
            }
            
            let opk = OneTimePreKeyLocal(preKeyId: preKeyId, privateKeyHandle: securePrivateKey!, publicKey: publicKeyBytes)
            return .success(opk)
        } catch {
            securePrivateKey?.dispose()
            if tempPrivateKeyBytes != nil {
                _ = SodiumInterop.secureWipe(&tempPrivateKeyBytes)
            }
            if tempPrivKeyCopy != nil {
                _ = SodiumInterop.secureWipe(&tempPrivKeyCopy)
            }
            return .failure(EcliptixProtocolFailure.generic("Unexpected failure during OPK generation for ID \(preKeyId)", inner: error))
        }
    }

    public func dispose() {
        if !privateKeyHandle.isInvalid {
            privateKeyHandle.dispose()
        }
    }
}


