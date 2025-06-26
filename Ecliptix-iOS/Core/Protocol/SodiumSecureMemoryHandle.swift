//
//  SodiumSecureMemoryHandle.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 23.05.2025.
//
import Foundation

enum SodiumSecureMemoryHandleException: Error {
    case invalidOperation(message: String)
    case objectDisposed(message: String)
}

final public class SodiumSecureMemoryHandle {
    private(set) var pointer: UnsafeMutableRawPointer?
    let length: Int
    private var refCount: Int = 1
    private(set) var isClosed: Bool = false

    private(set) var isAllocated: Bool
    
    var isInvalid: Bool {
        return !isAllocated
    }
        
    init(pointer: UnsafeMutableRawPointer?, length: Int, isAllocated: Bool) {
        self.pointer = pointer
        self.length = length
        self.isAllocated = isAllocated
    }

    deinit {
        if let ptr = pointer {
            SodiumInterop.sodium_free(ptr)
        }
    }

    static func allocate(length: Int) -> Result<SodiumSecureMemoryHandle, SodiumFailure> {
        if length < 0 {
            return .failure(.invalidBufferSize(String(format: SodiumFailureMessages.negativeAllocationLength, length)))
        }

        if length == 0 {
            return .success(SodiumSecureMemoryHandle(pointer: nil, length: 0, isAllocated: true))
        }

        do {
            guard SodiumInterop.isInitialized else {
                return .failure(.initializationFailed(SodiumFailureMessages.sodiumNotInitialized))
            }
            
            let allocationResult = executeWithErrorHandling(
                action: {
                    guard let ptr = SodiumInterop.sodium_malloc(length) else {
                        throw SodiumFailure.allocationFailed(
                            String(format: SodiumFailureMessages.unexpectedAllocationError, length)
                        )
                    }
                    return ptr
                },
                errorMapper: { error in
                    return SodiumFailure.allocationFailed(
                        String(format: SodiumFailureMessages.unexpectedAllocationError, length),
                        inner: error
                    )
                }
            )
            
            if allocationResult.isErr {
                return .failure(try allocationResult.unwrapErr())
            }
            
            var ptr = try allocationResult.unwrap()
            
            if ptr == nil {
                return .failure(.allocationFailed(String(format: SodiumFailureMessages.allocationFailed, length)))
            }
            
            return .success(SodiumSecureMemoryHandle(pointer: ptr, length: length, isAllocated: true))
        } catch {
            return .failure(.memoryProtectionFailed(String(format: SodiumFailureMessages.unexpectedAllocationError, length), inner: error))
        }
    }
    
    func write(data: UnsafeRawBufferPointer) -> Result<Unit, SodiumFailure> {
        if self.isInvalid || self.isClosed {
            return .failure(.nilPointer(String(format: SodiumFailureMessages.objectDisposed, String(describing: SodiumSecureMemoryHandle.self))))
        }

        if data.count > self.length {
            return .failure(.bufferTooLarge(String(format: SodiumFailureMessages.dataTooLarge, data.count, self.length)))
        }

        if data.isEmpty {
            return .success(Unit.value)
        }

        var success = false
        defer {
            if success {
                self.dangerousRelease()
            }
        }

        do {
            try self.dangerousAddRef(&success)
            guard success else {
                return .failure(.memoryPinningFailed(SodiumFailureMessages.referenceCountFailed))
            }

            if self.isInvalid || self.isClosed {
                return .failure(.nilPointer(String(format: SodiumFailureMessages.disposedAfterAddRef, String(describing: SodiumSecureMemoryHandle.self))))
            }

            memcpy(self.pointer, data.baseAddress, data.count)

            return .success(Unit.value)
        } catch {
            return .failure(.memoryProtectionFailed(SodiumFailureMessages.unexpectedWriteError, inner: error))
        }
    }
    
    func read(into destination: UnsafeMutableRawBufferPointer) -> Result<Unit, SodiumFailure> {
        if isInvalid || self.isClosed {
            return .failure(.nilPointer(String(format: SodiumFailureMessages.objectDisposed, String(describing: SodiumSecureMemoryHandle.self))))
        }

        if destination.count < length {
            return .failure(.bufferTooSmall(String(format: SodiumFailureMessages.objectDisposed, destination.count, self.length)))
        }

        if length == 0 {
            return .success(Unit.value)
        }

        var success = false
        defer {
            if success {
                dangerousRelease()
            }
        }
        
        do {
            try dangerousAddRef(&success)


            guard success else {
                return .failure(.memoryPinningFailed(SodiumFailureMessages.referenceCountFailed))
            }

            if isInvalid || isClosed {
                return .failure(.nilPointer(String(format: SodiumFailureMessages.disposedAfterAddRef, String(describing: SodiumSecureMemoryHandle.self))))
            }

            memcpy(destination.baseAddress, self.pointer, self.length)

            return .success(Unit.value)
        } catch {
            return .failure(.memoryProtectionFailed(SodiumFailureMessages.unexpectedReadError, inner: error))
        }
    }
    
    func readBytes(length: Int) -> Result<Data, SodiumFailure> {
        if isInvalid || isClosed {
            return .failure(.nilPointer(String(format: SodiumFailureMessages.objectDisposed, String(describing: SodiumSecureMemoryHandle.self))))
        }

        if length < 0 {
            return .failure(.invalidBufferSize(String(format: SodiumFailureMessages.negativeReadLength, length)))
        }

        if length > self.length {
            return .failure(.bufferTooSmall(String(format: SodiumFailureMessages.readLengthExceedsSize, length, self.length)))
        }

        if length == 0 {
            return .success(Data())
        }

        var success = false
        var buffer = Data(count: length)

        let copyResult = Self.executeWithErrorHandling(
            action: {
                try dangerousAddRef(&success)
                
                guard success else {
                    throw SodiumSecureMemoryHandleException.invalidOperation(message: SodiumFailureMessages.referenceCountFailed)
                }

                if isInvalid || isClosed {
                    throw SodiumSecureMemoryHandleException.objectDisposed(message: String(format: SodiumFailureMessages.disposedAfterAddRef, String(describing: SodiumSecureMemoryHandle.self)))
                }
                
                buffer.withUnsafeMutableBytes { destPtr in
                    guard let destBase = destPtr.baseAddress else { return }
                    memcpy(destBase, self.pointer, length)
                }
                
                return buffer
            }, errorMapper: { error in
                switch error {
                    case SodiumSecureMemoryHandleException.invalidOperation:
                        return SodiumFailure.memoryPinningFailed(SodiumFailureMessages.referenceCountFailed)
                    case SodiumSecureMemoryHandleException.objectDisposed:
                        return SodiumFailure.nilPointer(String(format: SodiumFailureMessages.disposedAfterAddRef, String(describing: SodiumSecureMemoryHandle.self)))
                    default:
                        return .memoryProtectionFailed(String(format: SodiumFailureMessages.unexpectedReadBytesError, length), inner: error)
                }
            }
        )
        
        if success {
            dangerousRelease()
        }
        
        return copyResult
    }

    func releaseHandle() -> Bool {
        if isInvalid {
            return true
        }
        
        guard SodiumInterop.isInitialized else {
            return false
        }
        
        if let ptr = pointer {
            SodiumInterop.sodium_free(ptr)
        }
        
        pointer = nil
        isClosed = true
        isAllocated = false
        
        return true
    }
    
    func dispose() {
        if !isClosed && pointer != nil {
            SodiumInterop.sodium_free(pointer)
            pointer = nil
            isClosed = true
            isAllocated = false
        }
    }
    
    private func dangerousAddRef(_ success: inout Bool) throws {
        if isClosed {
            success = false
            throw EcliptixProtocolFailure.objectDisposed("Memory handle already closed.")
        }
        refCount += 1
        success = true
    }

    private func dangerousRelease() {
        refCount -= 1
        if refCount <= 0 {
            if let ptr = pointer {
                SodiumInterop.sodium_free(ptr)
            }
            pointer = nil
            isClosed = true
            isAllocated = false
        }
    }
    
    private static func executeWithErrorHandling<Success>(
        action: () throws -> Success,
        errorMapper: (Error) -> SodiumFailure
    ) -> Result<Success, SodiumFailure> {
        do {
            let result = try action()
            return .success(result)
        } catch {
            return .failure(errorMapper(error))
        }
    }

}
