//
//  ServiceAction.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

public class ServiceAction: RetryableAction {
    
    private let serviceRequest: ServiceRequest
    
    public init(serviceRequest: ServiceRequest) {
        self.serviceRequest = serviceRequest
    }
    
    public func reqId() -> UInt32 {
        return serviceRequest.reqId
    }
    
    
}
