//
//  RetryCondition.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 18.06.2025.
//

import GRPC

enum RetryCondition {
    static func grpcUnavailableOnly(_ error: Error) -> Bool {
        if let grpcError = error as? GRPCStatus {
            return grpcError.code == .unavailable
        }
        return false
    }
    
    static func grpcDeadlineExceededOnly(_ error: Error) -> Bool {
        if let grpcError = error as? GRPCStatus {
            return grpcError.code == .deadlineExceeded
        }
        return false
    }
    
    static func grpcResourceExhaustedOnly(_ error: Error) -> Bool {
        if let grpcError = error as? GRPCStatus {
            return grpcError.code == .resourceExhausted
        }
        return false
    }
    
    static func retryAlways(_: Error) -> Bool {
        return true
    }
}
