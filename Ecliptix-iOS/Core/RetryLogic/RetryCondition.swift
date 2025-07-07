//
//  RetryCondition.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 18.06.2025.
//

import GRPC
import Foundation

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
        
        if String(describing: error).contains("RPC timed out before completing") {
            return true
        }

        return false
    }
    
    static func grpcResourceExhaustedOnly(_ error: Error) -> Bool {
        if let grpcError = error as? GRPCStatus {
            return grpcError.code == .resourceExhausted
        }
        return false
    }
    
    static func isUnauthorizedError(_ error: Error) -> Bool {
        if let grpcError = error as? GRPCStatus {
            return grpcError.code == .unauthenticated
        }
        return false
    }
}
