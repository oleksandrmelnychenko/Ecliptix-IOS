//
//  EventAggregatorProtocol.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.07.2025.
//

import Combine

protocol EventAggregatorProtocol {
    func getEvent<T>() -> AnyPublisher<T, Never>
    func publish<T>(_ message: T)
}
