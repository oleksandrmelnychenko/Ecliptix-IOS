//
//  SecrecyKeyExchangeServiceRequest.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 02.07.2025.
//

import SwiftProtobuf

final class SecrecyKeyExchangeServiceRequest<TRequest: SwiftProtobuf.Message, TResponse> {
    
    public let reqId: UInt32
    public let jobType: ServiceFlowType
    public let method: RpcServiceType
    public let pubKeyExchange: TRequest
    
    private init(
        reqId: UInt32,
        jobType: ServiceFlowType,
        method: RpcServiceType,
        pubKeyExchange: TRequest,
    ) {
        self.reqId = reqId
        self.jobType = jobType
        self.method = method
        self.pubKeyExchange = pubKeyExchange
    }
    
    public static func new(
        jobType: ServiceFlowType,
        method: RpcServiceType,
        pubKeyExchange: TRequest,
    ) -> SecrecyKeyExchangeServiceRequest<TRequest, TResponse> {
        let reqId = Helpers.generateRandomUInt32()
        return SecrecyKeyExchangeServiceRequest(
            reqId: reqId,
            jobType: jobType,
            method: method,
            pubKeyExchange: pubKeyExchange
        )
    }
}
