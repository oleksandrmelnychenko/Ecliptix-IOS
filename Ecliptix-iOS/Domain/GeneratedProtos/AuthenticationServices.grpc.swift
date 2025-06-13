// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the gRPC Swift generator plugin for the protocol buffer compiler.
// Source: AuthenticationServices.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/grpc/grpc-swift

import GRPCCore
import GRPCProtobuf

// MARK: - ecliptix.proto.membership.AuthVerificationServices

/// Namespace containing generated types for the "ecliptix.proto.membership.AuthVerificationServices" service.
public enum Ecliptix_Proto_Membership_AuthVerificationServices {
    /// Service descriptor for the "ecliptix.proto.membership.AuthVerificationServices" service.
    public static let descriptor = GRPCCore.ServiceDescriptor(fullyQualifiedService: "ecliptix.proto.membership.AuthVerificationServices")
    /// Namespace for method metadata.
    public enum Method {
        /// Namespace for "InitiateVerification" metadata.
        public enum InitiateVerification {
            /// Request type for "InitiateVerification".
            public typealias Input = Ecliptix_Proto_CipherPayload
            /// Response type for "InitiateVerification".
            public typealias Output = Ecliptix_Proto_CipherPayload
            /// Descriptor for "InitiateVerification".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "ecliptix.proto.membership.AuthVerificationServices"),
                method: "InitiateVerification"
            )
        }
        /// Namespace for "VerifyOtp" metadata.
        public enum VerifyOtp {
            /// Request type for "VerifyOtp".
            public typealias Input = Ecliptix_Proto_CipherPayload
            /// Response type for "VerifyOtp".
            public typealias Output = Ecliptix_Proto_CipherPayload
            /// Descriptor for "VerifyOtp".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "ecliptix.proto.membership.AuthVerificationServices"),
                method: "VerifyOtp"
            )
        }
        /// Namespace for "ValidatePhoneNumber" metadata.
        public enum ValidatePhoneNumber {
            /// Request type for "ValidatePhoneNumber".
            public typealias Input = Ecliptix_Proto_CipherPayload
            /// Response type for "ValidatePhoneNumber".
            public typealias Output = Ecliptix_Proto_CipherPayload
            /// Descriptor for "ValidatePhoneNumber".
            public static let descriptor = GRPCCore.MethodDescriptor(
                service: GRPCCore.ServiceDescriptor(fullyQualifiedService: "ecliptix.proto.membership.AuthVerificationServices"),
                method: "ValidatePhoneNumber"
            )
        }
        /// Descriptors for all methods in the "ecliptix.proto.membership.AuthVerificationServices" service.
        public static let descriptors: [GRPCCore.MethodDescriptor] = [
            InitiateVerification.descriptor,
            VerifyOtp.descriptor,
            ValidatePhoneNumber.descriptor
        ]
    }
}

extension GRPCCore.ServiceDescriptor {
    /// Service descriptor for the "ecliptix.proto.membership.AuthVerificationServices" service.
    public static let ecliptix_proto_membership_AuthVerificationServices = GRPCCore.ServiceDescriptor(fullyQualifiedService: "ecliptix.proto.membership.AuthVerificationServices")
}

// MARK: ecliptix.proto.membership.AuthVerificationServices (server)

extension Ecliptix_Proto_Membership_AuthVerificationServices {
    /// Streaming variant of the service protocol for the "ecliptix.proto.membership.AuthVerificationServices" service.
    ///
    /// This protocol is the lowest-level of the service protocols generated for this service
    /// giving you the most flexibility over the implementation of your service. This comes at
    /// the cost of more verbose and less strict APIs. Each RPC requires you to implement it in
    /// terms of a request stream and response stream. Where only a single request or response
    /// message is expected, you are responsible for enforcing this invariant is maintained.
    ///
    /// Where possible, prefer using the stricter, less-verbose ``ServiceProtocol``
    /// or ``SimpleServiceProtocol`` instead.
    public protocol StreamingServiceProtocol: GRPCCore.RegistrableRPCService {
        /// Handle the "InitiateVerification" method.
        ///
        /// - Parameters:
        ///   - request: A streaming request of `Ecliptix_Proto_CipherPayload` messages.
        ///   - context: Context providing information about the RPC.
        /// - Throws: Any error which occurred during the processing of the request. Thrown errors
        ///     of type `RPCError` are mapped to appropriate statuses. All other errors are converted
        ///     to an internal error.
        /// - Returns: A streaming response of `Ecliptix_Proto_CipherPayload` messages.
        func initiateVerification(
            request: GRPCCore.StreamingServerRequest<Ecliptix_Proto_CipherPayload>,
            context: GRPCCore.ServerContext
        ) async throws -> GRPCCore.StreamingServerResponse<Ecliptix_Proto_CipherPayload>

        /// Handle the "VerifyOtp" method.
        ///
        /// - Parameters:
        ///   - request: A streaming request of `Ecliptix_Proto_CipherPayload` messages.
        ///   - context: Context providing information about the RPC.
        /// - Throws: Any error which occurred during the processing of the request. Thrown errors
        ///     of type `RPCError` are mapped to appropriate statuses. All other errors are converted
        ///     to an internal error.
        /// - Returns: A streaming response of `Ecliptix_Proto_CipherPayload` messages.
        func verifyOtp(
            request: GRPCCore.StreamingServerRequest<Ecliptix_Proto_CipherPayload>,
            context: GRPCCore.ServerContext
        ) async throws -> GRPCCore.StreamingServerResponse<Ecliptix_Proto_CipherPayload>

        /// Handle the "ValidatePhoneNumber" method.
        ///
        /// - Parameters:
        ///   - request: A streaming request of `Ecliptix_Proto_CipherPayload` messages.
        ///   - context: Context providing information about the RPC.
        /// - Throws: Any error which occurred during the processing of the request. Thrown errors
        ///     of type `RPCError` are mapped to appropriate statuses. All other errors are converted
        ///     to an internal error.
        /// - Returns: A streaming response of `Ecliptix_Proto_CipherPayload` messages.
        func validatePhoneNumber(
            request: GRPCCore.StreamingServerRequest<Ecliptix_Proto_CipherPayload>,
            context: GRPCCore.ServerContext
        ) async throws -> GRPCCore.StreamingServerResponse<Ecliptix_Proto_CipherPayload>
    }

    /// Service protocol for the "ecliptix.proto.membership.AuthVerificationServices" service.
    ///
    /// This protocol is higher level than ``StreamingServiceProtocol`` but lower level than
    /// the ``SimpleServiceProtocol``, it provides access to request and response metadata and
    /// trailing response metadata. If you don't need these then consider using
    /// the ``SimpleServiceProtocol``. If you need fine grained control over your RPCs then
    /// use ``StreamingServiceProtocol``.
    public protocol ServiceProtocol: Ecliptix_Proto_Membership_AuthVerificationServices.StreamingServiceProtocol {
        /// Handle the "InitiateVerification" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Ecliptix_Proto_CipherPayload` message.
        ///   - context: Context providing information about the RPC.
        /// - Throws: Any error which occurred during the processing of the request. Thrown errors
        ///     of type `RPCError` are mapped to appropriate statuses. All other errors are converted
        ///     to an internal error.
        /// - Returns: A streaming response of `Ecliptix_Proto_CipherPayload` messages.
        func initiateVerification(
            request: GRPCCore.ServerRequest<Ecliptix_Proto_CipherPayload>,
            context: GRPCCore.ServerContext
        ) async throws -> GRPCCore.StreamingServerResponse<Ecliptix_Proto_CipherPayload>

        /// Handle the "VerifyOtp" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Ecliptix_Proto_CipherPayload` message.
        ///   - context: Context providing information about the RPC.
        /// - Throws: Any error which occurred during the processing of the request. Thrown errors
        ///     of type `RPCError` are mapped to appropriate statuses. All other errors are converted
        ///     to an internal error.
        /// - Returns: A response containing a single `Ecliptix_Proto_CipherPayload` message.
        func verifyOtp(
            request: GRPCCore.ServerRequest<Ecliptix_Proto_CipherPayload>,
            context: GRPCCore.ServerContext
        ) async throws -> GRPCCore.ServerResponse<Ecliptix_Proto_CipherPayload>

        /// Handle the "ValidatePhoneNumber" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Ecliptix_Proto_CipherPayload` message.
        ///   - context: Context providing information about the RPC.
        /// - Throws: Any error which occurred during the processing of the request. Thrown errors
        ///     of type `RPCError` are mapped to appropriate statuses. All other errors are converted
        ///     to an internal error.
        /// - Returns: A response containing a single `Ecliptix_Proto_CipherPayload` message.
        func validatePhoneNumber(
            request: GRPCCore.ServerRequest<Ecliptix_Proto_CipherPayload>,
            context: GRPCCore.ServerContext
        ) async throws -> GRPCCore.ServerResponse<Ecliptix_Proto_CipherPayload>
    }

    /// Simple service protocol for the "ecliptix.proto.membership.AuthVerificationServices" service.
    ///
    /// This is the highest level protocol for the service. The API is the easiest to use but
    /// doesn't provide access to request or response metadata. If you need access to these
    /// then use ``ServiceProtocol`` instead.
    public protocol SimpleServiceProtocol: Ecliptix_Proto_Membership_AuthVerificationServices.ServiceProtocol {
        /// Handle the "InitiateVerification" method.
        ///
        /// - Parameters:
        ///   - request: A `Ecliptix_Proto_CipherPayload` message.
        ///   - response: A response stream of `Ecliptix_Proto_CipherPayload` messages.
        ///   - context: Context providing information about the RPC.
        /// - Throws: Any error which occurred during the processing of the request. Thrown errors
        ///     of type `RPCError` are mapped to appropriate statuses. All other errors are converted
        ///     to an internal error.
        func initiateVerification(
            request: Ecliptix_Proto_CipherPayload,
            response: GRPCCore.RPCWriter<Ecliptix_Proto_CipherPayload>,
            context: GRPCCore.ServerContext
        ) async throws

        /// Handle the "VerifyOtp" method.
        ///
        /// - Parameters:
        ///   - request: A `Ecliptix_Proto_CipherPayload` message.
        ///   - context: Context providing information about the RPC.
        /// - Throws: Any error which occurred during the processing of the request. Thrown errors
        ///     of type `RPCError` are mapped to appropriate statuses. All other errors are converted
        ///     to an internal error.
        /// - Returns: A `Ecliptix_Proto_CipherPayload` to respond with.
        func verifyOtp(
            request: Ecliptix_Proto_CipherPayload,
            context: GRPCCore.ServerContext
        ) async throws -> Ecliptix_Proto_CipherPayload

        /// Handle the "ValidatePhoneNumber" method.
        ///
        /// - Parameters:
        ///   - request: A `Ecliptix_Proto_CipherPayload` message.
        ///   - context: Context providing information about the RPC.
        /// - Throws: Any error which occurred during the processing of the request. Thrown errors
        ///     of type `RPCError` are mapped to appropriate statuses. All other errors are converted
        ///     to an internal error.
        /// - Returns: A `Ecliptix_Proto_CipherPayload` to respond with.
        func validatePhoneNumber(
            request: Ecliptix_Proto_CipherPayload,
            context: GRPCCore.ServerContext
        ) async throws -> Ecliptix_Proto_CipherPayload
    }
}

// Default implementation of 'registerMethods(with:)'.
extension Ecliptix_Proto_Membership_AuthVerificationServices.StreamingServiceProtocol {
    public func registerMethods<Transport>(with router: inout GRPCCore.RPCRouter<Transport>) where Transport: GRPCCore.ServerTransport {
        router.registerHandler(
            forMethod: Ecliptix_Proto_Membership_AuthVerificationServices.Method.InitiateVerification.descriptor,
            deserializer: GRPCProtobuf.ProtobufDeserializer<Ecliptix_Proto_CipherPayload>(),
            serializer: GRPCProtobuf.ProtobufSerializer<Ecliptix_Proto_CipherPayload>(),
            handler: { request, context in
                try await self.initiateVerification(
                    request: request,
                    context: context
                )
            }
        )
        router.registerHandler(
            forMethod: Ecliptix_Proto_Membership_AuthVerificationServices.Method.VerifyOtp.descriptor,
            deserializer: GRPCProtobuf.ProtobufDeserializer<Ecliptix_Proto_CipherPayload>(),
            serializer: GRPCProtobuf.ProtobufSerializer<Ecliptix_Proto_CipherPayload>(),
            handler: { request, context in
                try await self.verifyOtp(
                    request: request,
                    context: context
                )
            }
        )
        router.registerHandler(
            forMethod: Ecliptix_Proto_Membership_AuthVerificationServices.Method.ValidatePhoneNumber.descriptor,
            deserializer: GRPCProtobuf.ProtobufDeserializer<Ecliptix_Proto_CipherPayload>(),
            serializer: GRPCProtobuf.ProtobufSerializer<Ecliptix_Proto_CipherPayload>(),
            handler: { request, context in
                try await self.validatePhoneNumber(
                    request: request,
                    context: context
                )
            }
        )
    }
}

// Default implementation of streaming methods from 'StreamingServiceProtocol'.
extension Ecliptix_Proto_Membership_AuthVerificationServices.ServiceProtocol {
    public func initiateVerification(
        request: GRPCCore.StreamingServerRequest<Ecliptix_Proto_CipherPayload>,
        context: GRPCCore.ServerContext
    ) async throws -> GRPCCore.StreamingServerResponse<Ecliptix_Proto_CipherPayload> {
        let response = try await self.initiateVerification(
            request: GRPCCore.ServerRequest(stream: request),
            context: context
        )
        return response
    }

    public func verifyOtp(
        request: GRPCCore.StreamingServerRequest<Ecliptix_Proto_CipherPayload>,
        context: GRPCCore.ServerContext
    ) async throws -> GRPCCore.StreamingServerResponse<Ecliptix_Proto_CipherPayload> {
        let response = try await self.verifyOtp(
            request: GRPCCore.ServerRequest(stream: request),
            context: context
        )
        return GRPCCore.StreamingServerResponse(single: response)
    }

    public func validatePhoneNumber(
        request: GRPCCore.StreamingServerRequest<Ecliptix_Proto_CipherPayload>,
        context: GRPCCore.ServerContext
    ) async throws -> GRPCCore.StreamingServerResponse<Ecliptix_Proto_CipherPayload> {
        let response = try await self.validatePhoneNumber(
            request: GRPCCore.ServerRequest(stream: request),
            context: context
        )
        return GRPCCore.StreamingServerResponse(single: response)
    }
}

// Default implementation of methods from 'ServiceProtocol'.
extension Ecliptix_Proto_Membership_AuthVerificationServices.SimpleServiceProtocol {
    public func initiateVerification(
        request: GRPCCore.ServerRequest<Ecliptix_Proto_CipherPayload>,
        context: GRPCCore.ServerContext
    ) async throws -> GRPCCore.StreamingServerResponse<Ecliptix_Proto_CipherPayload> {
        return GRPCCore.StreamingServerResponse<Ecliptix_Proto_CipherPayload>(
            metadata: [:],
            producer: { writer in
                try await self.initiateVerification(
                    request: request.message,
                    response: writer,
                    context: context
                )
                return [:]
            }
        )
    }

    public func verifyOtp(
        request: GRPCCore.ServerRequest<Ecliptix_Proto_CipherPayload>,
        context: GRPCCore.ServerContext
    ) async throws -> GRPCCore.ServerResponse<Ecliptix_Proto_CipherPayload> {
        return GRPCCore.ServerResponse<Ecliptix_Proto_CipherPayload>(
            message: try await self.verifyOtp(
                request: request.message,
                context: context
            ),
            metadata: [:]
        )
    }

    public func validatePhoneNumber(
        request: GRPCCore.ServerRequest<Ecliptix_Proto_CipherPayload>,
        context: GRPCCore.ServerContext
    ) async throws -> GRPCCore.ServerResponse<Ecliptix_Proto_CipherPayload> {
        return GRPCCore.ServerResponse<Ecliptix_Proto_CipherPayload>(
            message: try await self.validatePhoneNumber(
                request: request.message,
                context: context
            ),
            metadata: [:]
        )
    }
}

// MARK: ecliptix.proto.membership.AuthVerificationServices (client)

extension Ecliptix_Proto_Membership_AuthVerificationServices {
    /// Generated client protocol for the "ecliptix.proto.membership.AuthVerificationServices" service.
    ///
    /// You don't need to implement this protocol directly, use the generated
    /// implementation, ``Client``.
    public protocol ClientProtocol: Sendable {
        /// Call the "InitiateVerification" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Ecliptix_Proto_CipherPayload` message.
        ///   - serializer: A serializer for `Ecliptix_Proto_CipherPayload` messages.
        ///   - deserializer: A deserializer for `Ecliptix_Proto_CipherPayload` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func initiateVerification<Result>(
            request: GRPCCore.ClientRequest<Ecliptix_Proto_CipherPayload>,
            serializer: some GRPCCore.MessageSerializer<Ecliptix_Proto_CipherPayload>,
            deserializer: some GRPCCore.MessageDeserializer<Ecliptix_Proto_CipherPayload>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.StreamingClientResponse<Ecliptix_Proto_CipherPayload>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "VerifyOtp" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Ecliptix_Proto_CipherPayload` message.
        ///   - serializer: A serializer for `Ecliptix_Proto_CipherPayload` messages.
        ///   - deserializer: A deserializer for `Ecliptix_Proto_CipherPayload` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func verifyOtp<Result>(
            request: GRPCCore.ClientRequest<Ecliptix_Proto_CipherPayload>,
            serializer: some GRPCCore.MessageSerializer<Ecliptix_Proto_CipherPayload>,
            deserializer: some GRPCCore.MessageDeserializer<Ecliptix_Proto_CipherPayload>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Ecliptix_Proto_CipherPayload>) async throws -> Result
        ) async throws -> Result where Result: Sendable

        /// Call the "ValidatePhoneNumber" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Ecliptix_Proto_CipherPayload` message.
        ///   - serializer: A serializer for `Ecliptix_Proto_CipherPayload` messages.
        ///   - deserializer: A deserializer for `Ecliptix_Proto_CipherPayload` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        func validatePhoneNumber<Result>(
            request: GRPCCore.ClientRequest<Ecliptix_Proto_CipherPayload>,
            serializer: some GRPCCore.MessageSerializer<Ecliptix_Proto_CipherPayload>,
            deserializer: some GRPCCore.MessageDeserializer<Ecliptix_Proto_CipherPayload>,
            options: GRPCCore.CallOptions,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Ecliptix_Proto_CipherPayload>) async throws -> Result
        ) async throws -> Result where Result: Sendable
    }

    /// Generated client for the "ecliptix.proto.membership.AuthVerificationServices" service.
    ///
    /// The ``Client`` provides an implementation of ``ClientProtocol`` which wraps
    /// a `GRPCCore.GRPCCClient`. The underlying `GRPCClient` provides the long-lived
    /// means of communication with the remote peer.
    public struct Client<Transport>: ClientProtocol where Transport: GRPCCore.ClientTransport {
        private let client: GRPCCore.GRPCClient<Transport>

        /// Creates a new client wrapping the provided `GRPCCore.GRPCClient`.
        ///
        /// - Parameters:
        ///   - client: A `GRPCCore.GRPCClient` providing a communication channel to the service.
        public init(wrapping client: GRPCCore.GRPCClient<Transport>) {
            self.client = client
        }

        /// Call the "InitiateVerification" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Ecliptix_Proto_CipherPayload` message.
        ///   - serializer: A serializer for `Ecliptix_Proto_CipherPayload` messages.
        ///   - deserializer: A deserializer for `Ecliptix_Proto_CipherPayload` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        public func initiateVerification<Result>(
            request: GRPCCore.ClientRequest<Ecliptix_Proto_CipherPayload>,
            serializer: some GRPCCore.MessageSerializer<Ecliptix_Proto_CipherPayload>,
            deserializer: some GRPCCore.MessageDeserializer<Ecliptix_Proto_CipherPayload>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.StreamingClientResponse<Ecliptix_Proto_CipherPayload>) async throws -> Result
        ) async throws -> Result where Result: Sendable {
            try await self.client.serverStreaming(
                request: request,
                descriptor: Ecliptix_Proto_Membership_AuthVerificationServices.Method.InitiateVerification.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "VerifyOtp" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Ecliptix_Proto_CipherPayload` message.
        ///   - serializer: A serializer for `Ecliptix_Proto_CipherPayload` messages.
        ///   - deserializer: A deserializer for `Ecliptix_Proto_CipherPayload` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        public func verifyOtp<Result>(
            request: GRPCCore.ClientRequest<Ecliptix_Proto_CipherPayload>,
            serializer: some GRPCCore.MessageSerializer<Ecliptix_Proto_CipherPayload>,
            deserializer: some GRPCCore.MessageDeserializer<Ecliptix_Proto_CipherPayload>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Ecliptix_Proto_CipherPayload>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Ecliptix_Proto_Membership_AuthVerificationServices.Method.VerifyOtp.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }

        /// Call the "ValidatePhoneNumber" method.
        ///
        /// - Parameters:
        ///   - request: A request containing a single `Ecliptix_Proto_CipherPayload` message.
        ///   - serializer: A serializer for `Ecliptix_Proto_CipherPayload` messages.
        ///   - deserializer: A deserializer for `Ecliptix_Proto_CipherPayload` messages.
        ///   - options: Options to apply to this RPC.
        ///   - handleResponse: A closure which handles the response, the result of which is
        ///       returned to the caller. Returning from the closure will cancel the RPC if it
        ///       hasn't already finished.
        /// - Returns: The result of `handleResponse`.
        public func validatePhoneNumber<Result>(
            request: GRPCCore.ClientRequest<Ecliptix_Proto_CipherPayload>,
            serializer: some GRPCCore.MessageSerializer<Ecliptix_Proto_CipherPayload>,
            deserializer: some GRPCCore.MessageDeserializer<Ecliptix_Proto_CipherPayload>,
            options: GRPCCore.CallOptions = .defaults,
            onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Ecliptix_Proto_CipherPayload>) async throws -> Result = { response in
                try response.message
            }
        ) async throws -> Result where Result: Sendable {
            try await self.client.unary(
                request: request,
                descriptor: Ecliptix_Proto_Membership_AuthVerificationServices.Method.ValidatePhoneNumber.descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: options,
                onResponse: handleResponse
            )
        }
    }
}

// Helpers providing default arguments to 'ClientProtocol' methods.
extension Ecliptix_Proto_Membership_AuthVerificationServices.ClientProtocol {
    /// Call the "InitiateVerification" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Ecliptix_Proto_CipherPayload` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    public func initiateVerification<Result>(
        request: GRPCCore.ClientRequest<Ecliptix_Proto_CipherPayload>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.StreamingClientResponse<Ecliptix_Proto_CipherPayload>) async throws -> Result
    ) async throws -> Result where Result: Sendable {
        try await self.initiateVerification(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Ecliptix_Proto_CipherPayload>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Ecliptix_Proto_CipherPayload>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "VerifyOtp" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Ecliptix_Proto_CipherPayload` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    public func verifyOtp<Result>(
        request: GRPCCore.ClientRequest<Ecliptix_Proto_CipherPayload>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Ecliptix_Proto_CipherPayload>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.verifyOtp(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Ecliptix_Proto_CipherPayload>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Ecliptix_Proto_CipherPayload>(),
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ValidatePhoneNumber" method.
    ///
    /// - Parameters:
    ///   - request: A request containing a single `Ecliptix_Proto_CipherPayload` message.
    ///   - options: Options to apply to this RPC.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    public func validatePhoneNumber<Result>(
        request: GRPCCore.ClientRequest<Ecliptix_Proto_CipherPayload>,
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Ecliptix_Proto_CipherPayload>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        try await self.validatePhoneNumber(
            request: request,
            serializer: GRPCProtobuf.ProtobufSerializer<Ecliptix_Proto_CipherPayload>(),
            deserializer: GRPCProtobuf.ProtobufDeserializer<Ecliptix_Proto_CipherPayload>(),
            options: options,
            onResponse: handleResponse
        )
    }
}

// Helpers providing sugared APIs for 'ClientProtocol' methods.
extension Ecliptix_Proto_Membership_AuthVerificationServices.ClientProtocol {
    /// Call the "InitiateVerification" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    public func initiateVerification<Result>(
        _ message: Ecliptix_Proto_CipherPayload,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.StreamingClientResponse<Ecliptix_Proto_CipherPayload>) async throws -> Result
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Ecliptix_Proto_CipherPayload>(
            message: message,
            metadata: metadata
        )
        return try await self.initiateVerification(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "VerifyOtp" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    public func verifyOtp<Result>(
        _ message: Ecliptix_Proto_CipherPayload,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Ecliptix_Proto_CipherPayload>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Ecliptix_Proto_CipherPayload>(
            message: message,
            metadata: metadata
        )
        return try await self.verifyOtp(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }

    /// Call the "ValidatePhoneNumber" method.
    ///
    /// - Parameters:
    ///   - message: request message to send.
    ///   - metadata: Additional metadata to send, defaults to empty.
    ///   - options: Options to apply to this RPC, defaults to `.defaults`.
    ///   - handleResponse: A closure which handles the response, the result of which is
    ///       returned to the caller. Returning from the closure will cancel the RPC if it
    ///       hasn't already finished.
    /// - Returns: The result of `handleResponse`.
    public func validatePhoneNumber<Result>(
        _ message: Ecliptix_Proto_CipherPayload,
        metadata: GRPCCore.Metadata = [:],
        options: GRPCCore.CallOptions = .defaults,
        onResponse handleResponse: @Sendable @escaping (GRPCCore.ClientResponse<Ecliptix_Proto_CipherPayload>) async throws -> Result = { response in
            try response.message
        }
    ) async throws -> Result where Result: Sendable {
        let request = GRPCCore.ClientRequest<Ecliptix_Proto_CipherPayload>(
            message: message,
            metadata: metadata
        )
        return try await self.validatePhoneNumber(
            request: request,
            options: options,
            onResponse: handleResponse
        )
    }
}