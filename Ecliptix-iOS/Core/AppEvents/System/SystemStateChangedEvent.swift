//
//  Untitled.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.07.2025.
//

struct SystemStateChangedEvent {
    let state: SystemState

    private init(state: SystemState) {
        self.state = state
    }
    
    static func new(_ state: SystemState) -> SystemStateChangedEvent {
        SystemStateChangedEvent(state: state)
    }
}
