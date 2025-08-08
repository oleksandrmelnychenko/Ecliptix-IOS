//
//  CancellationToken.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 09.06.2025.
//

import Foundation

public class CancellationToken: @unchecked Sendable {
    private var isCancelled = false
    private let queue = DispatchQueue(label: "CancellationTokenQueue")

    func cancel() {
        queue.sync { isCancelled = true }
    }

    func throwIfCancelled() throws {
        try queue.sync {
            if isCancelled {
                throw CancellationError()
            }
        }
    }

    var cancelled: Bool {
        queue.sync { isCancelled }
    }
}

