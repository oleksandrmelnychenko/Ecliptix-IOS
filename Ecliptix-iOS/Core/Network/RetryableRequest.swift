//
//  RetryableRequest.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import Foundation

public class RetryableRequest {
    init(action: RetryableAction, createdAt: Date) {
        self.action = action
        self.createdAt = createdAt
    }
    
    public let action: RetryableAction
    public let createdAt: Date
}
