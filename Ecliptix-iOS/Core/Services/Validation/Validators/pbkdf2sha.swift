//
//  pbkdf2sha.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 18.06.2025.
//

import CommonCrypto
import Foundation

func pbkdf2sha(password: Data, salt: Data, iterations: Int, keyLength: Int) throws -> Data {
    var derivedKey = Data(repeating: 0, count: keyLength)
    
    let result = derivedKey.withUnsafeMutableBytes { derivedBytes in
        password.withUnsafeBytes { passwordBytes in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passwordBytes.bindMemory(to: Int8.self).baseAddress!,
                    password.count,
                    saltBytes.bindMemory(to: UInt8.self).baseAddress!,
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    UInt32(iterations),
                    derivedBytes.bindMemory(to: UInt8.self).baseAddress!,
                    keyLength
                )
            }
        }
    }

    if result != kCCSuccess {
        throw NSError(domain: "PBKDF2", code: Int(result), userInfo: nil)
    }

    return derivedKey
}
