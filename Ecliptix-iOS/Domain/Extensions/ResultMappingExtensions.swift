//
//  ResultSodiumExtensions.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 05.06.2025.
//

import Foundation
import SwiftProtobuf

extension Result where Success: Message, Failure == InternalValidationFailure {
    func prepareSerializedRequest(
        networkProvider: NetworkProvider,
        pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType = .dataCenterEphemeralConnect
    ) -> Result<(Data, UInt32), InternalValidationFailure> {
        return self
            .flatMap { request in
                ViewModelBase
                    .computeConnectId(networkProvider: networkProvider, pubKeyExchangeType: pubKeyExchangeType)
                    .mapInternalServiceApiFailure()
                    .map { connectId in (request, connectId) }
            }
            .flatMap { (request, connectId) in
                Result<(Data, UInt32), InternalValidationFailure>.Try({
                    (try request.serializedData(), connectId)
                }, errorMapper: { error in
                    .internalServiceApi("Failed to serialize request", inner: error)
                })
            }
    }
}

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

extension Result where Failure == InternalServiceApiFailure {
    func mapInternalServiceApiFailure() -> Result<Success, InternalValidationFailure> {
        switch self {
        case .success(let value):
            .success(value)
        case .failure(let internalServiceApiFailure):
            .failure(internalServiceApiFailure.toInternalValidationFailure())
        }
    }
}

extension Result where Failure == NetworkFailure {
    func mapNetworkFailure() -> Result<Success, InternalValidationFailure> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let networkFailure):
            return .failure(networkFailure.toInternalValidationFailure())
        }
    }
}

extension Result where Failure == OpaqueFailure {
    func mapOpaqueFailure() -> Result<Success, InternalValidationFailure> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let opaqueFailure):
            return .failure(opaqueFailure.toInternalValidationFailure())
        }
    }
}
