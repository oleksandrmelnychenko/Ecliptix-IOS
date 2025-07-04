//
//  RetryBackoff.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 18.06.2025.
//

import math_h

internal struct RetryBackoff {
    var baseDelay:  UInt64 = 500_000_000        // 0.5 s
    var maxDelay:   UInt64 = 10_000_000_000     // 10 s
    var multiplier: Double = 2.0               // e.g. 0.5 s → 1 s → 2 s …
    var jitter:     Double = 0.3               // ±30 %
    
    func delay(for attempt: Int) -> UInt64 {
        let raw = Double(baseDelay) * pow(multiplier, Double(attempt - 1))
        let clamped = min(raw, Double(maxDelay))

        let jitterFactor = 1 + (Double.random(in: -jitter...jitter))
        return UInt64(clamped * jitterFactor)
    }
}
