//
//  RetryableAction.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

public protocol RetryableAction {
    func reqId() -> UInt32
}
