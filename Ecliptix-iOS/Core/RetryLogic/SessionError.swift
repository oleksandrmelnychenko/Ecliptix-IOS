//
//  SessionError.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 19.06.2025.
//

import GRPC

enum SessionError: Error {
    case sessionExpired
    case other(Error)
    
    static func parse(from error: Error) -> SessionError {
        if let grpcError = error as? GRPCStatus,
           grpcError.message?.contains("not found or has timed out") == true {
            return .sessionExpired
        }
        return .other(error)
    }
}
