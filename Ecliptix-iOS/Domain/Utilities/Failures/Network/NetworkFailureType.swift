//
//  NetworkFailureType.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.07.2025.
//


public enum NetworkFailureType {
    case dataCenterNotResponding
    case dataCenterShutdown
    case invalidRequestType
    case ecliptixProtocolFailure
    case unexpectedError
}
