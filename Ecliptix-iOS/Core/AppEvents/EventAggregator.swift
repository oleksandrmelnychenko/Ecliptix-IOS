//
//  EventAggregator.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.07.2025.
//

import Foundation
import Combine

final class EventAggregator: EventAggregatorProtocol {
    private var subjects: [String: Any] = [:]
    private let lock = NSLock()
 
    func getEvent<T>() -> AnyPublisher<T, Never> {
        lock.lock(); defer { lock.unlock() }
        return getOrCreateSubject().eraseToAnyPublisher()
    }

    func publish<T>(_ message: T) {
        lock.lock(); defer { lock.unlock() }
        getOrCreateSubject().send(message)
    }
    
    private func getOrCreateSubject<T>() -> PassthroughSubject<T, Never> {
        let key = String(describing: T.self)
        
        if let subject = subjects[key] as? PassthroughSubject<T, Never> {
            return subject
        } else {
            let subject = PassthroughSubject<T, Never>()
            subjects[key] = subject
            return subject
        }
    }
}
