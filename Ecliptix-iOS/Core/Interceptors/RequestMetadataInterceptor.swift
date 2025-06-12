//
//  RequestMetadataInterceptor.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 11.06.2025.
//

import Foundation
import GRPC
import NIOCore
import NIOHPACK

final class RequestMetadataInterceptor<Request, Response>: ClientInterceptor<Request, Response>, @unchecked Sendable {
    private let appInstanceId: UUID
    private let deviceId: UUID

    init(appInstanceId: UUID, deviceId: UUID) {
        self.appInstanceId = appInstanceId
        self.deviceId = deviceId
    }

    override func send(
        _ part: GRPCClientRequestPart<Request>,
        promise: EventLoopPromise<Void>?,
        context: ClientInterceptorContext<Request, Response>
    ) {
        if case .metadata(var headers) = part {
            let extra = GrpcMetadataHandler.generateMetadata(appInstanceId: appInstanceId, appDeviceId: deviceId)
            for (name, value, _) in extra {
                headers.add(name: name, value: value)
            }
            context.send(.metadata(headers), promise: promise)
        } else {
            context.send(part, promise: promise)
        }
    }
}
