//
//  NetworkStatusChangedEvent.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.07.2025.
//

struct NetworkStatusChangedEvent {
    let state: NetworkStatus

    static func new(_ state: NetworkStatus) -> NetworkStatusChangedEvent {
        NetworkStatusChangedEvent(state: state)
    }
}
