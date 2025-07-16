//
//  SodiumFailureMessages.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 05.06.2025.
//

internal struct SodiumFailureMessages {
    public static let sodiumInitFailed = "sodium_init() returned an error code."
    public static let libraryLoadFailed = "Failed to load {0}. Ensure the native library is available and compatible."
    public static let initializationFailed = "Failed to initialize libsodium library."
    public static let unexpectedInitError = "An unexpected error occurred during libsodium initialization."
    public static let notInitialized = "SodiumInterop is not initialized. Cannot perform secure wipe.";
    public static let bufferNull = "Buffer cannot be null."
    public static let bufferTooLarge = "Buffer size ({0:N0} bytes) exceeds maximum ({1:N0} bytes)."
    public static let smallBufferClearFailed = "Failed to clear small buffer ({0} bytes) using Array.Clear."
    public static let pinningFailed = "Failed to pin buffer memory (GCHandle.Alloc). Invalid buffer or handle type."
    public static let insufficientMemory = "Insufficient memory to pin buffer (GCHandle.Alloc)."
    public static let addressOfPinnedObjectFailed = "GCHandle.Alloc succeeded, but AddrOfPinnedObject returned IntPtr.Zero for a non-empty buffer."
    public static let getPinnedAddressFailed = "Failed to get address of pinned buffer."
    public static let secureWipeFailed = "Unexpected error during secure wipe via sodium_memzero ({0} bytes)."
    
    public static let negativeAllocationLength = "Requested allocation length cannot be negative (%d)."
    public static let sodiumNotInitialized = "SodiumInterop is not initialized."
    public static let allocationFailed = "sodium_malloc failed to allocate {0} bytes."
    public static let unexpectedAllocationError = "Unexpected error during allocation (%d bytes)."
    public static let objectDisposed = "Cannot access disposed resource '%@'."
    public static let dataTooLarge = "Data length (%d) exceeds allocated buffer size (%d)."
    public static let referenceCountFailed = "Failed to increment reference count."
    public static let disposedAfterAddRef = "%@ disposed after AddRef."
    public static let unexpectedWriteError = "Unexpected error during write operation."
    public static let bufferTooSmall = "Destination buffer size ({0}) is smaller than the allocated size ({1})."
    public static let unexpectedReadError = "Unexpected error during read operation."
    public static let negativeReadLength = "Requested read length cannot be negative (%d)."
    public static let readLengthExceedsSize = "Requested read length (%d) exceeds allocated size (%d)."
    public static let unexpectedReadBytesError = "Unexpected error reading %d bytes."
}
