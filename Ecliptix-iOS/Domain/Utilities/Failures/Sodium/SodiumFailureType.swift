//
//  SodiumFailureType.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.07.2025.
//


import Foundation

enum SodiumFailureType {
    case initialzationFailed
    case libraryNotFound
    case allocationFailed
    case memoryPinningFailed
    case secureWipeFailed
    case invalidBufferSize
    case bufferTooSmall
    case bufferTooLarge
    case nilPointer
    case memoryProtectionFailed
    case comparisonFailed
}