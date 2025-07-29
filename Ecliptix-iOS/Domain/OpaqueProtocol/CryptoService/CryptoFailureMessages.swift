//
//  CryptoErrorMessages.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 29.07.2025.
//

struct CryptoFailureMessages {
    // Common
    static let failedToCreateContext = "Failed to create cipher context"
    static let invalidKeyLength = "Invalid key length"
    
    // Encryption
    static let encryptInitAlgorithm = "EncryptInit_ex (algorithm) failed"
    static let encryptInitKeyNonce = "EncryptInit_ex (key/nonce) failed"
    static let setIvLength = "Setting IV length failed"
    static let aadFailed = "AAD encryption failed"
    static let encryptUpdateFailed = "EncryptUpdate failed"
    static let encryptFinalFailed = "EncryptFinal failed"
    static let getTagFailed = "Get TAG failed"
    
    // Decryption
    static let decryptInitAlgorithm = "DecryptInit_ex (algorithm) failed"
    static let decryptInitKeyNonce = "DecryptInit_ex (key/nonce) failed"
    static let aadDecryptFailed = "AAD decryption failed"
    static let decryptUpdateFailed = "DecryptUpdate failed"
    static let setTagFailed = "Setting tag failed"
    static let decryptFinalFailed = "Invalid tag, authentication failed"
    
    // Validation
    static let ciphertextTooShort = "Ciphertext too short"
}
