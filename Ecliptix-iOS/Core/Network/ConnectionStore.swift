//
//  ConnectionStore.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 05.08.2025.
//

final class ConnectionStore {
    static let shared = ConnectionStore()
    
    private var connections: [UInt32: EcliptixProtocolSystem] = [:]
    private init() { }
    
    func get(for id: UInt32) -> EcliptixProtocolSystem? {
        connections[id]
    }
    
    func set(for id: UInt32, system: EcliptixProtocolSystem) {
        connections[id] = system
    }
    
    func remove(for id: UInt32) {
        connections.removeValue(forKey: id)
    }
}

