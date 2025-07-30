//
//  InternalServiceApiFailureType.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 23.07.2025.
//


import Security

enum InternalServiceApiFailureType {
    case secureStoreNotFound
    case secureStoreKeyNotFound
    case secureStoreAccessDenied
    case secureStoreUnknown
    
    case dependencyResolution
    case deserialization
    case serialization
}
