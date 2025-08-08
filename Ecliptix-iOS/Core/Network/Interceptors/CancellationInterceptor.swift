//
//  CancellationInterceptor.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//

import Foundation
import GRPC
import NIOCore
import NIOHPACK

final class CancellationInterceptor<Request, Response>: ClientInterceptor<Request, Response>, @unchecked Sendable {
    private let cancellationToken: CancellationToken

    init(cancellationToken: CancellationToken) {
        self.cancellationToken = cancellationToken
    }

    override func send(
        _ part: GRPCClientRequestPart<Request>,
        promise: EventLoopPromise<Void>?,
        context: ClientInterceptorContext<Request, Response>) {
        
        // Check if cancellation has been requested
        if cancellationToken.cancelled {
            // If cancelled, terminate the request and stop sending the part
            context.cancel(promise: promise)
            return
        }
        
        // If not cancelled, continue with the request as normal
        context.send(part, promise: promise)
    }
}

