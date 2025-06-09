//
//  ServiceRequest.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

class ServiceRequest {
    private init(reqId: UInt32, actionType: ServiceFlowType, rcpServiceMethod: RcpServiceAction, payload: Ecliptix_Proto_CipherPayload, encryptedChunls: [Ecliptix_Proto_CipherPayload]) {
        self.reqId = reqId
        self.actionType = actionType
        self.rcpServiceMethod = rcpServiceMethod
        self.payload = payload
        self.encryptedChunls = encryptedChunls
    }
    
    public let reqId: UInt32
    public let actionType: ServiceFlowType
    public let rcpServiceMethod: RcpServiceAction
    public let payload: Ecliptix_Proto_CipherPayload
    public let encryptedChunls: [Ecliptix_Proto_CipherPayload]
    
    public static func new(actionType: ServiceFlowType, rcpServiceMethod: RcpServiceAction, payload: Ecliptix_Proto_CipherPayload, encryptedChunls: [Ecliptix_Proto_CipherPayload]) -> ServiceRequest {
        let reqId = Utilities.generateRandomUInt32(in: 10...UInt32.max)
        return ServiceRequest(reqId: reqId, actionType: actionType, rcpServiceMethod: rcpServiceMethod, payload: payload, encryptedChunls: encryptedChunls)
    }
    
    public static func new(reqId: UInt32, actionType: ServiceFlowType, rcpServiceMethod: RcpServiceAction, payload: Ecliptix_Proto_CipherPayload, encryptedChunls: [Ecliptix_Proto_CipherPayload]) -> ServiceRequest {
        return ServiceRequest(reqId: reqId, actionType: actionType, rcpServiceMethod: rcpServiceMethod, payload: payload, encryptedChunls: encryptedChunls)
    }
}
