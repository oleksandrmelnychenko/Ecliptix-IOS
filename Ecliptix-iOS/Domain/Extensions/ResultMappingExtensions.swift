//
//  ResultSodiumExtensions.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 05.06.2025.
//

import Foundation

extension Result where Failure == SodiumFailure {
    func mapSodiumFailure() -> Result<Success, EcliptixProtocolFailure> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let sodiumFailure):
            return .failure(sodiumFailure.toEcliptixProtocolFailure())
        }
    }
}

extension Result where Failure == EcliptixProtocolFailure {
    func mapEcliptixProtocolFailure() -> Result<Success, NetworkFailure> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let ecliptixProtocolFailure):
            return .failure(ecliptixProtocolFailure.toNetworkFailure())
        }
    }
}
