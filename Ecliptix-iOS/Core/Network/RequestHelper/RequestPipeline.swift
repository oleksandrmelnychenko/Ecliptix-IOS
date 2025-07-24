//
//  RequestPipeline.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 23.07.2025.
//

import SwiftProtobuf

struct RequestPipeline {
    static func run<Req: Message, Res: Message>(
        requestResult: Result<Req, InternalValidationFailure>,
        pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType = .dataCenterEphemeralConnect,
        serviceType: RpcServiceType,
        flowType: ServiceFlowType,
        cancellationToken: CancellationToken,
        networkProvider: NetworkProvider,
        parseAndValidate: @escaping (Res) throws -> Result<Res, InternalValidationFailure>
    ) async -> Result<Res, InternalValidationFailure> {
        return await requestResult
            .prepareSerializedRequest(pubKeyExchangeType: pubKeyExchangeType)
            .flatMapAsync { (requestData, connectId) in
                await networkProvider.executeServiceAction(
                    connectId: connectId,
                    serviceType: serviceType,
                    plainBuffer: requestData,
                    flowType: flowType,
                    onSuccessCallback: { _ in .success(.value) },
                    token: cancellationToken
                ).mapNetworkFailure()
            }
            .flatMap { payload in
                Result<Res, InternalValidationFailure>.Try({
                    let response = try Helpers.parseFromBytes(Res.self, data: payload)
                    return try parseAndValidate(response).unwrap()
                }, errorMapper: { error in
                    if let failure = error as? InternalValidationFailure {
                        return failure
                    } else {
                        return .internalServiceApi("Failed to parse \(Res.self) response", inner: error)
                    }
                })
            }
    }
    
    static func runAsync<Req: Message, Res: Message>(
        requestResult: Result<Req, InternalValidationFailure>,
        pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType = .dataCenterEphemeralConnect,
        serviceType: RpcServiceType,
        flowType: ServiceFlowType,
        cancellationToken: CancellationToken,
        networkProvider: NetworkProvider,
        parseAndValidate: @escaping (Res) async throws -> Result<Res, InternalValidationFailure>
    ) async -> Result<Res, InternalValidationFailure> {
        return await requestResult
            .prepareSerializedRequest(pubKeyExchangeType: pubKeyExchangeType)
            .flatMapAsync { (requestData, connectId) in
                await networkProvider.executeServiceAction(
                    connectId: connectId,
                    serviceType: serviceType,
                    plainBuffer: requestData,
                    flowType: flowType,
                    onSuccessCallback: { _ in .success(.value) },
                    token: cancellationToken
                ).mapNetworkFailure()
            }
            .flatMapAsync { payload in
                await Result<Res, InternalValidationFailure>.TryAsync({
                    let response = try Helpers.parseFromBytes(Res.self, data: payload)
                    return try await parseAndValidate(response).unwrap()
                }, errorMapper: { error in
                    if let failure = error as? InternalValidationFailure {
                        return failure
                    } else {
                        return .internalServiceApi("Failed to parse \(Res.self) response", inner: error)
                    }
                })
            }
    }
}
