//
//  AesGcmService.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 23.05.2025.
//

import Foundation
import CryptoKit

// TODO: not the best approach I guess
enum AesGcmError: Error, LocalizedError {
    case invalidKeyLength
    case invalidNonceLength
    case invalidTagLength
    case bufferTooSmall
    case encryptFailed(underlying: Error)
    case decryptFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidKeyLength:
            return "Invalid AES key length"
        case .invalidNonceLength:
            return "Invalid AES-GCM nonce length"
        case .invalidTagLength:
            return "Invalid AES-GCM tag length"
        case .bufferTooSmall:
            return "Destination buffer is too small"
        case .encryptFailed(let underlying):
            return "AES-GCM encryption failed: \(underlying.localizedDescription)"
        case .decryptFailed(let underlying):
            return "AES-GCM decryption failed (authentication tag mismatch): \(underlying.localizedDescription)"
        }
    }
}


/// AES-256-GCM authenticated encryption and decryption service.
/// NOTE: Nonce uniqueness per key is CRITICAL for AES-GCM security.
class AesGcmService {
    /// Encrypts plaintext using AES-256-GCM.
    /// - Parameters:
    ///   - key: 32-byte symmetric key.
    ///   - nonce: 12-byte nonce (must be unique per key).
    ///   - plaintext: Data to encrypt.
    ///   - associatedData: Optional associated data for authentication.
    /// - Returns: Tuple with ciphertext and authentication tag.
    /// - Throws: `Error` on invalid inputs or encryption failure.
    public static func encrypt(
        key: Data,
        nonce: Data,
        plaintext: Data,
        ciphertextDestination: UnsafeMutableBufferPointer<UInt8>,
        tagDestination: UnsafeMutableBufferPointer<UInt8>,
        associatedData: Data = Data()
    ) throws {
        guard key.count == Constants.aesKeySize else {
            throw AesGcmError.invalidKeyLength
        }
        guard nonce.count == Constants.aesGcmNonceSize else {
            throw AesGcmError.invalidNonceLength
        }
        guard tagDestination.count == Constants.aesGcmTagSize else {
            throw AesGcmError.invalidTagLength
        }
        guard ciphertextDestination.count >= plaintext.count else {
            throw AesGcmError.bufferTooSmall
        }
        
        do {
            let symmetricKey = SymmetricKey(data: key)
            let gcmNonce = try AES.GCM.Nonce(data: nonce)
            let sealedBox = try AES.GCM.seal(plaintext, using: symmetricKey, nonce: gcmNonce, authenticating: associatedData)
            
            // Copy ciphertext to ciphertextDestination buffer
            sealedBox.ciphertext.copyBytes(to: ciphertextDestination.baseAddress!, count: sealedBox.ciphertext.count)
            
            // Copy tag to tagDestination buffer
            sealedBox.tag.copyBytes(to: tagDestination.baseAddress!, count: sealedBox.tag.count)
        } catch {
            throw AesGcmError.encryptFailed(underlying: error)
        }
    }
    
    /// Decrypts ciphertext using AES-256-GCM and verifies the authentication tag.
    /// - Parameters:
    ///   - key: 32-byte symmetric key.
    ///   - nonce: 12-byte nonce used during encryption.
    ///   - ciphertext: Encrypted data.
    ///   - tag: 16-byte authentication tag.
    ///   - associatedData: Optional associated data that must match encryption.
    /// - Returns: Decrypted plaintext data.
    /// - Throws: `Error` on invalid inputs or decryption failure.
    static func decrypt(
        key: Data,
        nonce: Data,
        ciphertext: Data,
        tag: Data,
        plaintextDestination: UnsafeMutableBufferPointer<UInt8>,
        associatedData: Data = Data()
    ) throws {
        guard key.count == Constants.aesKeySize else {
            throw AesGcmError.invalidKeyLength
        }
        guard nonce.count == Constants.aesGcmNonceSize else {
            throw AesGcmError.invalidNonceLength
        }
        guard tag.count == Constants.aesGcmTagSize else {
            throw AesGcmError.invalidTagLength
        }
        guard plaintextDestination.count >= ciphertext.count else {
            throw AesGcmError.bufferTooSmall
        }
        
        do {
            let symmetricKey = SymmetricKey(data: key)
            let gcmNonce = try AES.GCM.Nonce(data: nonce)
            let sealedBox = try AES.GCM.SealedBox(nonce: gcmNonce, ciphertext: ciphertext, tag: tag)
            
            let plaintext = try AES.GCM.open(sealedBox, using: symmetricKey, authenticating: associatedData)
            
            // Copy plaintext bytes to plaintextDestination buffer
            plaintext.copyBytes(to: plaintextDestination.baseAddress!, count: plaintext.count)
        } catch {
            throw AesGcmError.decryptFailed(underlying: error)
        }
    }
    
    static func encryptAllocating(
        key: Data,
        nonce: Data,
        plaintext: Data,
        associatedData: Data = Data()
    ) throws -> (ciphertext: Data, tag: Data) {
        var ciphertext = Data(count: plaintext.count)
        var tag = Data(count: Constants.aesGcmTagSize)
        
        try ciphertext.withUnsafeMutableBytes { ctPtr in
            try tag.withUnsafeMutableBytes { tagPtr in
                try encrypt(
                    key: key,
                    nonce: nonce,
                    plaintext: plaintext,
                    ciphertextDestination: ctPtr.bindMemory(to: UInt8.self),
                    tagDestination: tagPtr.bindMemory(to: UInt8.self),
                    associatedData: associatedData)
            }
        }
        return (ciphertext, tag)
    }

    static func decryptAllocating(
        key: Data,
        nonce: Data,
        ciphertext: Data,
        tag: Data,
        associatedData: Data = Data()
    ) throws -> Data {
        var plaintext = Data(count: ciphertext.count)

        try plaintext.withUnsafeMutableBytes { ptRawPtr in
            guard let ptBase = ptRawPtr.bindMemory(to: UInt8.self).baseAddress else {
                throw EcliptixProtocolFailure.generic("Plaintext buffer allocation failed.")
            }

            let buffer = UnsafeMutableBufferPointer<UInt8>(start: ptBase, count: ciphertext.count)

            try decrypt(
                key: key,
                nonce: nonce,
                ciphertext: ciphertext,
                tag: tag,
                plaintextDestination: buffer,
                associatedData: associatedData)
        }


        return plaintext
    }
}

