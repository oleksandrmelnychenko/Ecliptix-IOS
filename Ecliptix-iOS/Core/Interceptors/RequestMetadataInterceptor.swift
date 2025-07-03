//
//  RequestMetadataInterceptor.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 11.06.2025.
//

import Foundation
@preconcurrency import GRPC
import NIOCore
import NIOHPACK

final class RequestMetadataInterceptor<Request, Response>: ClientInterceptor<Request, Response>, @unchecked Sendable {
    private let rpcMetaDataProvider: RpcMetaDataProviderProtocol

    init(rpcMetaDataProvider: RpcMetaDataProviderProtocol) {
        self.rpcMetaDataProvider = rpcMetaDataProvider
    }

    override func send(
        _ part: GRPCClientRequestPart<Request>,
        promise: EventLoopPromise<Void>?,
        context: ClientInterceptorContext<Request, Response>) {
        if case .metadata(var headers) = part {
//            Task {
                let appInstanceId = self.rpcMetaDataProvider.getAppInstanceId().uuidString
                let deviceId = self.rpcMetaDataProvider.getDeviceId().uuidString
//                let appInstanceId = "00000000-0000-0000-0000-000000000000"
//                let deviceId = "00000000-0000-0000-0000-000000000000"
                
                let extra = GrpcMetadataHandler.generateMetadata(
                    appInstanceId: appInstanceId,
                    appDeviceId: deviceId
                )
                
                for (name, value, _) in extra {
                    headers.add(name: name, value: value)
                }
                
                // 🔐 Повернення на EventLoop — через копію значень
//                eventLoop.execute {
//                    // Тепер можна безпечно використовувати context
//                    context.send(.metadata(headers), promise: promise)
//                }
            
            context.send(.metadata(headers), promise: promise)
//            }
        } else {
            context.send(part, promise: promise)
        }
    }
}
