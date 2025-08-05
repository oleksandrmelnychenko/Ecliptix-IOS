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
    
    static func runStream<Req: Message, Res: Message>(
        requestResult: Result<Req, InternalValidationFailure>,
        pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType = .dataCenterEphemeralConnect,
        serviceType: RpcServiceType,
        cancellationToken: CancellationToken,
        networkProvider: NetworkProvider,
        parseAndValidate: @escaping (Res) throws -> Result<Res, InternalValidationFailure>
    ) -> AsyncStream<Result<Res, InternalValidationFailure>> {

        return AsyncStream { continuation in
            Task {
                let result = await requestResult
                    .prepareSerializedRequest(pubKeyExchangeType: pubKeyExchangeType)
                    .flatMapAsync { (requestData, connectId) in
                        await networkProvider.executeStreamServiceAction(
                            connectId: connectId,
                            serviceType: serviceType,
                            plainBuffer: requestData,
                            token: cancellationToken
                        ).mapNetworkFailure()
                    }

                switch result {
                case .failure(let failure):
                    continuation.yield(.failure(failure))
                    continuation.finish()

                case .success(let stream):
                    do {
                        for try await item in stream {
                            switch item {
                            case .failure(let failure):
                                continuation.yield(.failure(failure.toInternalValidationFailure()))
                            case .success(let data):
                                let parsed = Result<Res, InternalValidationFailure>.Try({
                                    let response = try Helpers.parseFromBytes(Res.self, data: data)
                                    return try parseAndValidate(response).unwrap()
                                }, errorMapper: {
                                    .internalServiceApi("Failed to parse stream \(Res.self)", inner: $0)
                                })

                                continuation.yield(parsed)
                            }
                        }
                        continuation.finish()
                    } catch {
                        continuation.yield(.failure(.internalServiceApi("Stream error", inner: error)))
                        continuation.finish()
                    }
                }
            }
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
