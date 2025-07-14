//
//  SystemEventsProtocol.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.07.2025.
//

import Combine

protocol SystemEventsProtocol {
    var systemStateChanged: AnyPublisher<SystemStateChangedEvent, Never> { get }
    func publish(_ message: SystemStateChangedEvent)
}
