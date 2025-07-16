//
//  EcliptixProtocolFailureType.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.07.2025.
//


import Foundation

enum EcliptixProtocolFailureType {
    case generic
    case decodeFailed
    case deriveKeyFailed
    case handshakeFailed
    case peerPubKeyFailed
    case invalidInput
    case objectDisposed
    case allocationFailed
    case pinningFailure
    case bufferTooSmall
    case dataTooLarge
    case keyGenerationFailed
    case prepareBufferError
    case memoryBufferError
    case unexpectedError
}
