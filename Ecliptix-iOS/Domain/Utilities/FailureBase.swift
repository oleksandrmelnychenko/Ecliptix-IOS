//
//  FailureBase.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 24.06.2025.
//

import Foundation
import GRPC

protocol FailureBaseProtocol {
    func toStructuredLog() -> Any
    func toGrpcStatus() -> GRPCStatus
}

class FailureBase: FailureBaseProtocol {
    let message: String
    let innerError: Error?
    let timestamp: Date

    init(message: String, innerError: Error? = nil) {
        self.message = message
        self.innerError = innerError
        self.timestamp = Date()
    }

    func toStructuredLog() -> Any {
        fatalError("Must override")
    }

    func toGrpcStatus() -> GRPCStatus {
        fatalError("Must override")
    }
}
