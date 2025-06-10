//
//  PubKeyExchangeAction.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

public class PubKeyExchangeAction: RetryableAction {
    private let pubKeyExchangeAction: PubKeyExchangeActionInvokable
    
    init(pubKeyExchangeAction: PubKeyExchangeActionInvokable) {
        self.pubKeyExchangeAction = pubKeyExchangeAction
    }
    
    public func reqId() -> UInt32 {
        return self.pubKeyExchangeAction.reqId
    }
}
