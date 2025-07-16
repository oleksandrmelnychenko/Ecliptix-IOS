//
//  NetworkStatusChangedEvent.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.07.2025.
//

struct NetworkStatusChangedEvent {
    let state: NetworkStatus

    private init(state: NetworkStatus) {
        self.state = state
    }
    
    static func new(_ state: NetworkStatus) -> NetworkStatusChangedEvent {
        NetworkStatusChangedEvent(state: state)
    }
}
