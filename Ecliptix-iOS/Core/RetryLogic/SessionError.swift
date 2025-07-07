//
//  SessionError.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 19.06.2025.
//

import GRPC

enum SessionError: Error, Equatable {
    case sessionExpired
    case other(Error)
    
    static func parse(from error: Error) -> SessionError {
        if let grpcError = error as? GRPCStatus,
           grpcError.message?.contains("not found or has timed out") == true {
            return .sessionExpired
        }
        return .other(error)
    }
    
    static func == (lhs: SessionError, rhs: SessionError) -> Bool {
        return lhs.localizedDescription == rhs.localizedDescription
    }
}
