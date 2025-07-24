//
//  InternalValidationFailureType.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 23.07.2025.
//


enum InternalValidationFailureType {
    case deviceIdUnavailable
    case invalidValue
    case phoneNumberIsGuid
    
    case secureStoreError
    case networkError
    case internalServiceApi
    
    case unknown
}
