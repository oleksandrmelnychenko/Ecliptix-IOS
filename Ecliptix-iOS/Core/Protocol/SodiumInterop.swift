//
//  SodiumInterop.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 22.05.2025.
//

import Foundation

enum SodiumInteropException: Error {
    case invalidOperation(message: String)
    case objectDisposed(message: String)
}

final class SodiumInterop {
    private static let libSodium = "libsodium"
    private static let maxBufferSize = 1_000_000_000
    private static let smallBufferThreshold = 64
    private static let initalizationResult: Result<Unit, SodiumFailure> = {
        return initializeSodium()
    }()
    
    static let isInitialized: Bool = {
        return initalizationResult.isOk
    }()

    private init() {}
    
    //    static let isInitialized: Bool = {
    //        let result = sodium_init()
    //        guard result >= 0 else {
    //            fatalError("sodium_init() returned error")
    //        }
    //        return true
    //    }

    // MARK: - Libsodium function imports
    @discardableResult
    public static func sodium_init() -> Int32 {
        return _sodium_init()
    }

    public static func sodium_malloc(_ size: Int) -> UnsafeMutableRawPointer? {
        return _sodium_malloc(size)
    }

    public static func sodium_free(_ ptr: UnsafeMutableRawPointer?) {
        _sodium_free(ptr)
    }

    public static func sodium_memzero(_ ptr: UnsafeMutableRawPointer?, _ length: Int) {
        _sodium_memzero(ptr, length)
    }
    
    /// Securely wipes the buffer content using libsodium or fallback to clearing array.
    /// Returns .success(Void) or .failure(ShieldFailure)
    static func secureWipe(_ buffer: inout Data?) -> Result<Unit, SodiumFailure> {
        
        guard isInitialized else {
            return .failure(.initializationFailed(SodiumFailureMessages.notInitialized))
        }
        
        guard var unwrapped = buffer else {
            return .failure(.bufferTooSmall(SodiumFailureMessages.bufferNull))
        }

        let result = secureWipe(&unwrapped)
        
        switch result {
        case .success:
            buffer = unwrapped
            return .success(Unit.value)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    static func secureWipe(_ buffer: inout Data) -> Result<Unit, SodiumFailure> {
        if buffer.isEmpty {
            return .success(Unit.value)
        }
        
        return Result<Data, SodiumFailure>.validate(buffer, predicate: { buf in buf.count <= maxBufferSize }, error: .bufferTooLarge(String(format: SodiumFailureMessages.bufferTooLarge, buffer.count, maxBufferSize)))
            .flatMap { validBuffer -> Result<Unit, SodiumFailure> in
                return validBuffer.count <= smallBufferThreshold ? wipeSmallBuffer(&buffer) : wipeLargeBuffer(&buffer)
            }
    }
    

    // MARK: - Private helpers

    private static func wipeSmallBuffer(_ buffer: inout Data) -> Result<Unit, SodiumFailure> {
        buffer.resetBytes(in: 0..<buffer.count)
        return .success(Unit.value)
    }
    
    private static func wipeLargeBuffer(_ buffer: inout Data) -> Result<Unit, SodiumFailure> {
        return Result<Result<Unit, SodiumFailure>, SodiumFailure>.Try {
            let count = buffer.count

            return buffer.withUnsafeMutableBytes { rawBuffer -> Result<Unit, SodiumFailure> in
                guard let baseAddress = rawBuffer.baseAddress else {
                    return .failure(.secureWipeFailed("Failed to get base address of pinned buffer."))
                }

                sodium_memzero(baseAddress, count)
                return .success(Unit())
            }
        }
        .flatMap { $0 }
        .mapError { error in
            return error
        }
    }
    
    private static func initializeSodium() -> Result<Unit, SodiumFailure> {
        return Result<Unit, SodiumFailure>.Try {
            let result = sodium_init()
            let dllImportSuccess = 0
            if result < dllImportSuccess {
                throw SodiumInteropException.invalidOperation(message: SodiumFailureMessages.sodiumInitFailed)
            }
            return Unit.value
        }.mapError { error in
            return SodiumFailure.initializationFailed(SodiumFailureMessages.unexpectedInitError, inner: error)
        }
    }
}

// MARK: - Bridging to libsodium C functions

@discardableResult
private func _sodium_init() -> Int32 {
    // The actual symbol must be linked properly; replace with actual import
    return c_sodium_init()
}

private func _sodium_malloc(_ size: Int) -> UnsafeMutableRawPointer? {
    return c_sodium_malloc(size)
}

private func _sodium_free(_ ptr: UnsafeMutableRawPointer?) {
    c_sodium_free(ptr)
}

private func _sodium_memzero(_ ptr: UnsafeMutableRawPointer?, _ length: Int) {
    c_sodium_memzero(ptr, length)
}

// MARK: - C function declarations

@_silgen_name("sodium_init")
private func c_sodium_init() -> Int32

@_silgen_name("sodium_malloc")
private func c_sodium_malloc(_ size: Int) -> UnsafeMutableRawPointer?

@_silgen_name("sodium_free")
private func c_sodium_free(_ ptr: UnsafeMutableRawPointer?)

@_silgen_name("sodium_memzero")
private func c_sodium_memzero(_ ptr: UnsafeMutableRawPointer?, _ length: Int)
