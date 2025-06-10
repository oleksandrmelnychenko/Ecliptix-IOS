//
//  CancellationToken.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 09.06.2025.
//

public class CancellationToken {
    private var isCancelled = false
    func cancel() {
        isCancelled = true
    }
    func throwIfCancelled() throws {
        if isCancelled {
            throw CancellationError()
        }
    }
    var cancelled: Bool { isCancelled }
}
