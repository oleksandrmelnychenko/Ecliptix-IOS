//
//  ServiceRequest.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

class ServiceRequest {
    public let reqId: UInt32
    public let actionType: ServiceFlowType
    public let rcpServiceMethod: RpcServiceType
    public let payload: Ecliptix_Proto_CipherPayload
    public let encryptedChunls: [Ecliptix_Proto_CipherPayload]
    
    private init(
        reqId: UInt32,
        actionType: ServiceFlowType,
        rcpServiceMethod: RpcServiceType,
        payload: Ecliptix_Proto_CipherPayload,
        encryptedChunls: [Ecliptix_Proto_CipherPayload])
    {
        self.reqId = reqId
        self.actionType = actionType
        self.rcpServiceMethod = rcpServiceMethod
        self.payload = payload
        self.encryptedChunls = encryptedChunls
    }
    

    
    public static func new(
        actionType: ServiceFlowType,
        rcpServiceMethod: RpcServiceType,
        payload: Ecliptix_Proto_CipherPayload,
        encryptedChunls: [Ecliptix_Proto_CipherPayload]
    ) -> ServiceRequest {
        
        let reqId = Helpers.generateRandomUInt32(in: 10...UInt32.max)
        return ServiceRequest(
            reqId: reqId,
            actionType: actionType,
            rcpServiceMethod: rcpServiceMethod,
            payload: payload,
            encryptedChunls: encryptedChunls)
    }
}
