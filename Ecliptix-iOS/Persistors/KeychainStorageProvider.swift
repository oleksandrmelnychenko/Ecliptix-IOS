//
//  SecureStorageProvider.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 02.07.2025.
//

import Foundation

final class KeychainStorageProvider: SecureStorageProviderProtocol {
    
    private let ttlDays: Int

    init(ttlDays: Int = 90) {
        self.ttlDays = ttlDays
    }

    func store(key: String, data: Data) -> Result<Unit, InternalServiceApiFailure> {
        let expirationDate = Calendar.current.date(byAdding: .day, value: ttlDays, to: Date()) ?? Date()
        let payload = ExpiringKeyValue(data: data, expirationDate: expirationDate)
        
        guard let encoded = try? JSONEncoder().encode(payload) else {
            return .failure(.secureStoreNotFound("Encoding error"))
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: encoded
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
            ? .success(.value)
            : .failure(.fromOSStatus(status, context: "store"))
    }
    
    func tryGetByKey(key: String) -> Result<Data?, InternalServiceApiFailure> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let rawData = result as? Data,
                  let decoded = try? JSONDecoder().decode(ExpiringKeyValue.self, from: rawData) else {
                return .failure(.secureStoreNotFound("Decode failed"))
            }

            if decoded.expirationDate < Date() {
                _ = delete(key: key)
                return .success(nil)
            }

            return .success(decoded.data)
        case errSecItemNotFound:
            return .success(nil)
        default:
            return .failure(.fromOSStatus(status, context: "tryGetByKey"))
        }
    }
    
    func delete(key: String) -> Result<Unit, InternalServiceApiFailure> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess, errSecItemNotFound:
            return .success(.value)
        default:
            return .failure(.fromOSStatus(status, context: "delete(key: \(key))"))
        }
    }
}
