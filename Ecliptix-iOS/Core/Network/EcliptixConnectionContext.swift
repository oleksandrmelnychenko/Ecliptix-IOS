//
//  EcliptixConnectionContext.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

internal final class EcliptixConnectionContext {
    public let pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType
    public let ecliptixProtocolSystem: EcliptixProtocolSystem
    
    init(pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType, ecliptixProtocolSystem: EcliptixProtocolSystem) {
        self.pubKeyExchangeType = pubKeyExchangeType
        self.ecliptixProtocolSystem = ecliptixProtocolSystem
    }
}
