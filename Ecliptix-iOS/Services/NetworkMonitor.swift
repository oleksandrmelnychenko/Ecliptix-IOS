//
//  NetworkMonitor.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 24.07.2025.
//

import Network
import Combine

final class NetworkMonitor: ObservableObject {
    @Published var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
