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
    
//    private static let lowercaseRegex = try! NSRegularExpression(pattern: "[a-z]", options: [])
//    private static let uppercaseRegex = try! NSRegularExpression(pattern: "[A-Z]", options: [])
//    private static let digitRegex = try! NSRegularExpression(pattern: "\\d", options: [])
//    private static let alphanumericOnlyRegex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9]*$", options: [])
    
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
    
//    func checkPasswordCompliance(_ password: String?, policy: PasswordPolicy) -> Result<Unit, EcliptixProtocolFailure> {
//        
//        guard let password = password else {
//            return .failure(.invalidInput("Password policy is missing."))
//        }
//
//        var validationErrorMessages: [String] = []
//
//        if password.isEmpty {
//            validationErrorMessages.append("Password cannot be empty.")
//        } else {
//            if password.count < policy.minLength {
//                validationErrorMessages.append("Password must be at least \(policy.minLength) characters long.")
//            }
//            
//            let range = NSRange(location: 0, length: password.utf16.count)
//            if policy.requireLowercase && Self.lowercaseRegex.firstMatch(in: password, range: range) == nil {
//                validationErrorMessages.append("Password must contain at least one lowercase letter.")
//            }
//            
//            if policy.requireUppercase && Self.uppercaseRegex.firstMatch(in: password, range: range) == nil {
//                validationErrorMessages.append("Password must contain at least one uppercase letter.")
//            }
//            
//            if policy.requireDigit && Self.digitRegex.firstMatch(in: password, range: range) == nil {
//                validationErrorMessages.append("Password must contain at least one digit.")
//            }
//
//            if policy.requireSpecialChar && !policy.allowedSpecialChars.isEmpty {
//                let escaped = NSRegularExpression.escapedPattern(for: policy.allowedSpecialChars)
//                let pattern = "[\(escaped)]"
//                
//                if let regex = try? NSRegularExpression(pattern: pattern) {
//                    if regex.firstMatch(in: password, range: range) == nil {
//                        validationErrorMessages.append("Password must contain at least one special character from the set: \(policy.allowedSpecialChars).")
//                    }
//                }
//            }
//
//            if policy.enforceAllowedCharsOnly {
//                if !policy.allowedSpecialChars.isEmpty {
//                    let escaped = NSRegularExpression.escapedPattern(for: policy.allowedSpecialChars)
//                    let pattern = "^[a-zA-Z0-9\(escaped)]*$"
//                    
//                    if let regex = try? NSRegularExpression(pattern: pattern) {
//                        if regex.firstMatch(in: password, range: range) == nil {
//                            validationErrorMessages.append("Password contains characters that are not allowed. Only alphanumeric and specified special characters are permitted.")
//                        }
//                    }
//                } else {
//                    if Self.alphanumericOnlyRegex.firstMatch(in: password, range: range) == nil {
//                        validationErrorMessages.append("Password contains characters that are not allowed. Only alphanumeric characters are permitted.")
//                    }
//                }
//            }
//        }
//
//        if !validationErrorMessages.isEmpty {
//            let combined = validationErrorMessages.joined(separator: "; ")
//            return .failure(.invalidInput("Password does not meet complexity requirements: \(combined)"))
//        }
//
//        return .success(.value)
//    }
    
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
