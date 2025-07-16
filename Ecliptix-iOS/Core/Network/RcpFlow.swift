//
//  RcpFlow.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import Foundation

public class RpcFlow {
    final class SingleCall: RpcFlow {
        public let result: () async -> Result<Ecliptix_Proto_CipherPayload, NetworkFailure>

        public init(result: @escaping () async -> Result<Ecliptix_Proto_CipherPayload, NetworkFailure>) {
            self.result = result
        }

        public convenience init(immediate: Result<Ecliptix_Proto_CipherPayload, NetworkFailure>) {
            self.init { immediate }
        }
    }
    
    final class InboundStream: RpcFlow {
        let stream: AsyncThrowingStream<Result<Ecliptix_Proto_CipherPayload, NetworkFailure>, Error>

        init(stream: AsyncThrowingStream<Result<Ecliptix_Proto_CipherPayload, NetworkFailure>, Error>) {
            self.stream = stream
        }
    }
    
    final class OutboundSink: RpcFlow {
        let sink: IOutboundSink

        init(sink: IOutboundSink) {
            self.sink = sink
        }
    }
    
    final class BidirectionalStream: RpcFlow {
        let inbound: AsyncThrowingStream<Result<Ecliptix_Proto_CipherPayload, NetworkFailure>, Error>
        let outbound: IOutboundSink

        init(inbound: AsyncThrowingStream<Result<Ecliptix_Proto_CipherPayload, NetworkFailure>, Error>, outbound: IOutboundSink) {
            self.inbound = inbound
            self.outbound = outbound
        }
    }
    
    // Factory methods
    static func newEmptyInboundStream() -> RpcFlow {
        let stream = AsyncThrowingStream<Result<Ecliptix_Proto_CipherPayload, NetworkFailure>, Error> { continuation in
            continuation.finish()
        }
        return InboundStream(stream: stream)
    }
    
    static func newDrainOutboundSink() -> RpcFlow {
        return OutboundSink(sink: DrainSink())
    }

    static func newBidirectionalStream() -> RpcFlow {
        let (stream, sink) = ChannelSink.createChannel()
        return BidirectionalStream(inbound: stream, outbound: sink)
    }
    
    static func toOkStream(from stream: AsyncStream<Ecliptix_Proto_CipherPayload>) -> AsyncStream<Result<Ecliptix_Proto_CipherPayload, NetworkFailure>> {
        return AsyncStream { continuation in
            Task {
                for await payload in stream {
                    continuation.yield(.success(payload))
                }
                continuation.finish()
            }
        }
    }

    public init() {
        if type(of: self) == RpcFlow.self {
            fatalError("RpcFlow is an abstract base class and cannot be instantiated directly.")
        }
    }
    
}

internal class DrainSink : IOutboundSink {
    func sendAsync(_ payload: Ecliptix_Proto_CipherPayload) async -> Result<Unit, NetworkFailure> {
        .success(.value)
    }
}

internal class ChannelSink : IOutboundSink {
    private let continuation: AsyncThrowingStream<Result<Ecliptix_Proto_CipherPayload, NetworkFailure>, Error>.Continuation

    private init(continuation: AsyncThrowingStream<Result<Ecliptix_Proto_CipherPayload, NetworkFailure>, Error>.Continuation) {
        self.continuation = continuation
    }
    
    func sendAsync(_ payload: Ecliptix_Proto_CipherPayload) async -> Result<Unit, NetworkFailure> {
        continuation.yield(.success(payload))
        return .success(.value)
    }

    static func createChannel() -> (AsyncThrowingStream<Result<Ecliptix_Proto_CipherPayload, NetworkFailure>, Error>, ChannelSink) {
        var savedContinuation: AsyncThrowingStream<Result<Ecliptix_Proto_CipherPayload, NetworkFailure>, Error>.Continuation!

        let stream = AsyncThrowingStream<Result<Ecliptix_Proto_CipherPayload, NetworkFailure>, Error> { continuation in
            savedContinuation = continuation
        }

        let sink = ChannelSink(continuation: savedContinuation)
        return (stream, sink)
    }
}
