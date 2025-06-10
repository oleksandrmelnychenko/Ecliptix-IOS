//
//  RcpFlow.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import Foundation

public class RpcFlow {
    
    class SingleCall: RpcFlow {
        public let result: Task<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>, Never>

        init(result: Task<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>, Never>) {
            self.result = result
        }

        convenience init(immediate: Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>) {
            self.init(result: Task { immediate })
        }
    }
    
    class InboundStream: RpcFlow {
        let stream: AsyncStream<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>>

        init(stream: AsyncStream<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>>) {
            self.stream = stream
        }
    }
    
    class OutboundSink: RpcFlow {
        let sink: IOutboundSink

        init(sink: IOutboundSink) {
            self.sink = sink
        }
    }
    
    class BidirectionalStream: RpcFlow {
        let inbound: AsyncStream<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>>
        let outbound: IOutboundSink

        init(inbound: AsyncStream<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>>, outbound: IOutboundSink) {
            self.inbound = inbound
            self.outbound = outbound
        }
    }
    
    // Factory methods
    static func newEmptyInboundStream() -> RpcFlow {
        let stream = AsyncStream<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>> { continuation in
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
    
    static func toOkStream(from stream: AsyncStream<Ecliptix_Proto_CipherPayload>) -> AsyncStream<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>> {
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
    func sendAsync(_ payload: Ecliptix_Proto_CipherPayload) async -> Result<Unit, EcliptixProtocolFailure> {
        .success(.value)
    }
}

internal class ChannelSink : IOutboundSink {
    private let continuation: AsyncStream<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>>.Continuation

    private init(continuation: AsyncStream<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>>.Continuation) {
        self.continuation = continuation
    }
    
    func sendAsync(_ payload: Ecliptix_Proto_CipherPayload) async -> Result<Unit, EcliptixProtocolFailure> {
        continuation.yield(.success(payload))
        return .success(.value)
    }

    static func createChannel() -> (AsyncStream<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>>, ChannelSink) {
        var savedContinuation: AsyncStream<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>>.Continuation!

        let stream = AsyncStream<Result<Ecliptix_Proto_CipherPayload, EcliptixProtocolFailure>> { continuation in
            savedContinuation = continuation
        }

        let sink = ChannelSink(continuation: savedContinuation)
        return (stream, sink)
    }
}
