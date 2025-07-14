//
//  SystemEvents.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.07.2025.
//

import Combine

final class SystemEvents: SystemEventsProtocol {
    private let aggregator: EventAggregatorProtocol
    
    init(aggregator: EventAggregatorProtocol) {
        self.aggregator = aggregator
    }
    
    var systemStateChanged: AnyPublisher<SystemStateChangedEvent, Never> {
        self.aggregator.getEvent()
    }
    
    func publish(_ message: SystemStateChangedEvent) {
        self.aggregator.publish(message)
    }
}
