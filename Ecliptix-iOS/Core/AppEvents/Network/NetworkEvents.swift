//
//  NetworkEvents.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.07.2025.
//

import Combine

class NetworkEvents: NetworkEventsProtocol {
    private var currentState: NetworkStatus?
    private let aggregator: EventAggregatorProtocol
    
    init(aggregator: EventAggregatorProtocol) {
        self.aggregator = aggregator
    }
    
    var networkStatusChanged: AnyPublisher<NetworkStatusChangedEvent, Never> {
        aggregator.getEvent()
    }
    
    func initiateChangeState(_ message: NetworkStatusChangedEvent) {
        if let current = currentState, current == message.state {
            return
        }

        self.currentState = message.state
        self.aggregator.publish(message)
    }
}
