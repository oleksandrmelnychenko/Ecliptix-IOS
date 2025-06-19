//
//  PasswordManager.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

import Foundation
import CryptoKit

final class PasswordManager {
    private static let defaultSaltSize: Int = 16
    private static let defaultIterations: Int = 600_000
    private static let hashSeparator: Character = ":"
    
    private let iterations: Int
    private let hashAlgorithmName: HashAlgorithmName
    private let saltSize: Int
    
    private init(iterations: Int, hashAlgorithmName: HashAlgorithmName, saltSize: Int) {
        self.iterations = iterations
        self.hashAlgorithmName = hashAlgorithmName
        self.saltSize = saltSize
    }
    
    static func create(iterations: Int = defaultIterations, hashAlgorithmName: HashAlgorithmName? = nil, saltSize: Int = defaultSaltSize) -> Result<PasswordManager, EcliptixProtocolFailure> {
            
            guard iterations > 0 else {
                return .failure(.invalidInput("PasswordManager configuration: Iterations must be a positive integer."))
            }
            
            guard saltSize > 0 else {
                return .failure(.invalidInput("PasswordManager configuration: Salt size must be a positive integer."))
            }
            
            let effectiveHash = hashAlgorithmName ?? .sha256
            
            guard effectiveHash.isSupported else {
                return .failure(.invalidInput("PasswordManager configuration: Unsupported hash algorithm '\(effectiveHash.rawValue)'. Supported for PBKDF2 are SHA1, SHA256, SHA384, SHA512."))
            }
            
            return .success(PasswordManager(
                iterations: iterations,
                hashAlgorithmName: effectiveHash,
                saltSize: saltSize
            ))
        }
    
    func hashPassword(_ password: String) -> Result<String, EcliptixProtocolFailure> {
        guard !password.isEmpty else {
            return .failure(.invalidInput("Password to hash cannot be null or empty."))
        }

        do {
            let salt = Data()
            let passwordData = Data(password.utf8)
            let keyLength = Self.getHashSize(for: self.hashAlgorithmName)

            let derivedKey = try pbkdf2sha(password: passwordData, salt: salt, iterations: iterations, keyLength: keyLength)

            let base64Hash = derivedKey.base64EncodedString()
            return .success("\(Self.hashSeparator)\(base64Hash)")
        } catch {
            return .failure(.deriveKey("An unexpected error occurred during PBKDF2 password hashing.", inner: error))
        }
    }

    private static func getHashSize(for algorithm: HashAlgorithmName) -> Int {
        switch algorithm {
        case .sha1:
            return 20
        case .sha256:
            return 32
        case .sha384:
            return 48
        case .sha512:
            return 64
        }
    }
}


enum HashAlgorithmName: String {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha384 = "SHA384"
    case sha512 = "SHA512"
    
    var isSupported: Bool {
        switch self {
        case .sha1, .sha256, .sha384, .sha512:
            return true
        }
    }
}
