//
//  SodiumInterop.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 22.05.2025.
//

import Foundation
import Sodium

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
    
    static func generateX25519KeyPair(keyPurpose: String) -> Result<(skHandle: SodiumSecureMemoryHandle, pk: Data), EcliptixProtocolFailure>
        {
        var skHandle: SodiumSecureMemoryHandle? = nil;
        var tempPrivCopy: Data?  = nil;
        
        do
        {
            let allocResult = SodiumSecureMemoryHandle.allocate(length: Constants.x25519PrivateKeySize)
            if allocResult.isErr {
                return .failure(try allocResult.unwrapErr().toEcliptixProtocolFailure());
            }
            
            skHandle = try allocResult.unwrap();
            
            guard let randomBytes = Sodium().randomBytes.buf(length: Constants.x25519PrivateKeySize) else {
                skHandle?.dispose()
                return .failure(.generic("Failed to generate random bytes for \(keyPurpose)"))
            }
            var skBytes: Data = Data(randomBytes)
            
            let writeResult = skBytes.withUnsafeBytes { bufferPointer in
                skHandle!.write(data: bufferPointer)
            }
            _ = secureWipe(&skBytes)
            if writeResult.isErr {
                skHandle?.dispose()
                return .failure(try writeResult.unwrapErr().toEcliptixProtocolFailure())
            }
            
            tempPrivCopy = Data(count: Constants.x25519PrivateKeySize)
            let readResult = tempPrivCopy!.withUnsafeMutableBytes { destPtr in
                skHandle!.read(into: destPtr)
            }
            if readResult.isErr {
                skHandle?.dispose()
                _ = SodiumInterop.secureWipe(&tempPrivCopy)
                return .failure(try readResult.unwrapErr().toEcliptixProtocolFailure())
            }
            
            let deriveResult = Result<Data, EcliptixProtocolFailure>.Try {
                return try ScalarMult.base(&tempPrivCopy!)
            }.mapError { error in
                EcliptixProtocolFailure.generic("Failed to derive \(keyPurpose) public key.", inner: error)
            }
            
            _ = SodiumInterop.secureWipe(&tempPrivCopy)
            tempPrivCopy = nil;
            
            if deriveResult.isErr {
                skHandle?.dispose()
                return .failure(try deriveResult.unwrapErr())
            }
            
            var pkBytes = try deriveResult.unwrap()
            if pkBytes.count != Constants.x25519PublicKeySize {
                skHandle?.dispose()
                _ = SodiumInterop.secureWipe(&pkBytes)
                return .failure(.generic("Derived \(keyPurpose) public key has incorrect size."))
            }
            
            return .success((skHandle!, pkBytes))
        }
        catch
        {
            skHandle?.dispose()
            if tempPrivCopy != nil {
                _ = SodiumInterop.secureWipe(&tempPrivCopy)
            }
            return .failure(.keyGeneration("Unexpected error generating \(keyPurpose) key pair.", inner: error))
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
