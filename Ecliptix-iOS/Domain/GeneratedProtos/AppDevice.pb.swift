// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: AppDevice.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

public struct Ecliptix_Proto_AppDevice_AppDevice: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var appInstanceID: Data = Data()

  public var deviceID: Data = Data()

  public var deviceType: Ecliptix_Proto_AppDevice_AppDevice.DeviceType = .mobile

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public enum DeviceType: SwiftProtobuf.Enum, Swift.CaseIterable {
    public typealias RawValue = Int
    case mobile // = 0
    case desktop // = 1
    case UNRECOGNIZED(Int)

    public init() {
      self = .mobile
    }

    public init?(rawValue: Int) {
      switch rawValue {
      case 0: self = .mobile
      case 1: self = .desktop
      default: self = .UNRECOGNIZED(rawValue)
      }
    }

    public var rawValue: Int {
      switch self {
      case .mobile: return 0
      case .desktop: return 1
      case .UNRECOGNIZED(let i): return i
      }
    }

    // The compiler won't synthesize support with the UNRECOGNIZED case.
    public static let allCases: [Ecliptix_Proto_AppDevice_AppDevice.DeviceType] = [
      .mobile,
      .desktop,
    ]

  }

  public init() {}
}

public struct Ecliptix_Proto_AppDevice_AppDeviceRegisteredStateReply: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var status: Ecliptix_Proto_AppDevice_AppDeviceRegisteredStateReply.Status = .successNewRegistration

  public var uniqueID: Data = Data()

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public enum Status: SwiftProtobuf.Enum, Swift.CaseIterable {
    public typealias RawValue = Int
    case successNewRegistration // = 0
    case successAlreadyExists // = 1
    case failureInvalidRequest // = 2
    case failureInternalError // = 3
    case UNRECOGNIZED(Int)

    public init() {
      self = .successNewRegistration
    }

    public init?(rawValue: Int) {
      switch rawValue {
      case 0: self = .successNewRegistration
      case 1: self = .successAlreadyExists
      case 2: self = .failureInvalidRequest
      case 3: self = .failureInternalError
      default: self = .UNRECOGNIZED(rawValue)
      }
    }

    public var rawValue: Int {
      switch self {
      case .successNewRegistration: return 0
      case .successAlreadyExists: return 1
      case .failureInvalidRequest: return 2
      case .failureInternalError: return 3
      case .UNRECOGNIZED(let i): return i
      }
    }

    // The compiler won't synthesize support with the UNRECOGNIZED case.
    public static let allCases: [Ecliptix_Proto_AppDevice_AppDeviceRegisteredStateReply.Status] = [
      .successNewRegistration,
      .successAlreadyExists,
      .failureInvalidRequest,
      .failureInternalError,
    ]

  }

  public init() {}
}

public struct Ecliptix_Proto_AppDevice_AppDeviceSettings: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var appID: Data = Data()

  public var deviceID: Data = Data()

  public var language: String = String()

  public var serverUniqueID: Data = Data()

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "ecliptix.proto.app_device"

extension Ecliptix_Proto_AppDevice_AppDevice: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".AppDevice"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "app_instance_id"),
    2: .standard(proto: "device_id"),
    3: .standard(proto: "device_type"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.appInstanceID) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.deviceID) }()
      case 3: try { try decoder.decodeSingularEnumField(value: &self.deviceType) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.appInstanceID.isEmpty {
      try visitor.visitSingularBytesField(value: self.appInstanceID, fieldNumber: 1)
    }
    if !self.deviceID.isEmpty {
      try visitor.visitSingularBytesField(value: self.deviceID, fieldNumber: 2)
    }
    if self.deviceType != .mobile {
      try visitor.visitSingularEnumField(value: self.deviceType, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Ecliptix_Proto_AppDevice_AppDevice, rhs: Ecliptix_Proto_AppDevice_AppDevice) -> Bool {
    if lhs.appInstanceID != rhs.appInstanceID {return false}
    if lhs.deviceID != rhs.deviceID {return false}
    if lhs.deviceType != rhs.deviceType {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Ecliptix_Proto_AppDevice_AppDevice.DeviceType: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "MOBILE"),
    1: .same(proto: "DESKTOP"),
  ]
}

extension Ecliptix_Proto_AppDevice_AppDeviceRegisteredStateReply: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".AppDeviceRegisteredStateReply"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "status"),
    2: .standard(proto: "unique_id"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularEnumField(value: &self.status) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.uniqueID) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.status != .successNewRegistration {
      try visitor.visitSingularEnumField(value: self.status, fieldNumber: 1)
    }
    if !self.uniqueID.isEmpty {
      try visitor.visitSingularBytesField(value: self.uniqueID, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Ecliptix_Proto_AppDevice_AppDeviceRegisteredStateReply, rhs: Ecliptix_Proto_AppDevice_AppDeviceRegisteredStateReply) -> Bool {
    if lhs.status != rhs.status {return false}
    if lhs.uniqueID != rhs.uniqueID {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Ecliptix_Proto_AppDevice_AppDeviceRegisteredStateReply.Status: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "SUCCESS_NEW_REGISTRATION"),
    1: .same(proto: "SUCCESS_ALREADY_EXISTS"),
    2: .same(proto: "FAILURE_INVALID_REQUEST"),
    3: .same(proto: "FAILURE_INTERNAL_ERROR"),
  ]
}

extension Ecliptix_Proto_AppDevice_AppDeviceSettings: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".AppDeviceSettings"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "app_id"),
    2: .standard(proto: "device_id"),
    3: .same(proto: "language"),
    4: .standard(proto: "server_unique_id"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.appID) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.deviceID) }()
      case 3: try { try decoder.decodeSingularStringField(value: &self.language) }()
      case 4: try { try decoder.decodeSingularBytesField(value: &self.serverUniqueID) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.appID.isEmpty {
      try visitor.visitSingularBytesField(value: self.appID, fieldNumber: 1)
    }
    if !self.deviceID.isEmpty {
      try visitor.visitSingularBytesField(value: self.deviceID, fieldNumber: 2)
    }
    if !self.language.isEmpty {
      try visitor.visitSingularStringField(value: self.language, fieldNumber: 3)
    }
    if !self.serverUniqueID.isEmpty {
      try visitor.visitSingularBytesField(value: self.serverUniqueID, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Ecliptix_Proto_AppDevice_AppDeviceSettings, rhs: Ecliptix_Proto_AppDevice_AppDeviceSettings) -> Bool {
    if lhs.appID != rhs.appID {return false}
    if lhs.deviceID != rhs.deviceID {return false}
    if lhs.language != rhs.language {return false}
    if lhs.serverUniqueID != rhs.serverUniqueID {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
