//
//  PubKeyExchangeActionInvokable.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

public class PubKeyExchangeActionInvokable {
    private init(reqId: UInt32, jobType: ServiceFlowType, method: RcpServiceAction, pubKeyExchange: Ecliptix_Proto_PubKeyExchange, onComplete: ((Ecliptix_Proto_PubKeyExchange) -> Void)?) {
        self.reqId = reqId
        self.jobType = jobType
        self.method = method
        self.pubKeyExchange = pubKeyExchange
        self.onComplete = onComplete
    }
    
    public let reqId: UInt32
    public let jobType: ServiceFlowType
    public let method: RcpServiceAction
    public let pubKeyExchange: Ecliptix_Proto_PubKeyExchange
    public let onComplete: ((Ecliptix_Proto_PubKeyExchange) -> Void)?
    
    public static func new(jobType: ServiceFlowType, method: RcpServiceAction, pubKeyExchange: Ecliptix_Proto_PubKeyExchange, callback: ((Ecliptix_Proto_PubKeyExchange) -> Void)? = nil) -> PubKeyExchangeActionInvokable{
        
        let reqId = Utilities.generateRandomUInt32()
        return PubKeyExchangeActionInvokable(reqId: reqId, jobType: jobType, method: method, pubKeyExchange: pubKeyExchange, onComplete: callback)
    }

    public static func new(reqId: UInt32, jobType: ServiceFlowType, method: RcpServiceAction, pubKeyExchange: Ecliptix_Proto_PubKeyExchange, callback: ((Ecliptix_Proto_PubKeyExchange) -> Void)? = nil) -> PubKeyExchangeActionInvokable{
        
        return PubKeyExchangeActionInvokable(reqId: reqId, jobType: jobType, method: method, pubKeyExchange: pubKeyExchange, onComplete: callback)
    }
}
