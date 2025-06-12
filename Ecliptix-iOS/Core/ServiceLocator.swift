//
//  ServiceLocator.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 11.06.2025.
//

final class ServiceLocator {
    static let shared = ServiceLocator()
    
    private var services: [ObjectIdentifier: Any] = [:]

    private init() {}

    func register<T>(_ type: T.Type, service: T) {
        let key = ObjectIdentifier(type)
        services[key] = service
    }

    func resolve<T>(_ type: T.Type) -> T {
        let key = ObjectIdentifier(type)
        guard let service = services[key] as? T else {
            fatalError("No registered service for type \(type)")
        }
        return service
    }
}
