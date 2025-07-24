//
//  ServiceLocator.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 11.06.2025.
//

import Foundation

enum ServiceLocatorError: Error, LocalizedError {
    case serviceNotRegistered(type: Any.Type)
    
    var errorDescription: String? {
        switch self {
        case .serviceNotRegistered(let type):
            return "No registered service for type \(type)"
        }
    }
}

final class ServiceLocator {
    static let shared = ServiceLocator()
    
    private var services: [ObjectIdentifier: Any] = [:]

    private init() {}

    func register<T>(_ type: T.Type, service: T) {
        let key = ObjectIdentifier(type)
        self.services[key] = service
    }

    func resolve<T>(_ type: T.Type) throws -> T {
        let key = ObjectIdentifier(type)
        guard let service = services[key] as? T else {
            throw ServiceLocatorError.serviceNotRegistered(type: type)
        }
        return service
    }
}
