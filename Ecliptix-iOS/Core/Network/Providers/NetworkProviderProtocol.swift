//
//  NetworkProviderProtocol.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 07.07.2025.
//

protocol NetworkProviderProtocol {
    func restoreSecrecyChannelAsync() async -> Result<Unit, EcliptixProtocolFailure>

    func setSecrecyChannelAsUnhealthy()
}
