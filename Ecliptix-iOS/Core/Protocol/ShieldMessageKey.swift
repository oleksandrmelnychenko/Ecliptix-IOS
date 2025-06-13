//
//  ShieldMessageKey.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 26.05.2025.
//

import Foundation

final class ShieldMessageKey: Equatable, Hashable {
    private var disposed: Bool
    private var keyHandle: SodiumSecureMemoryHandle
    let index: UInt32

    private init(index: UInt32, keyHandle: SodiumSecureMemoryHandle) {
        self.index = index
        self.keyHandle = keyHandle
        disposed = false
    }

    deinit {
        dispose(disposing: false)
    }

    static func new(index: UInt32, keyMaterial: inout Data) -> Result<ShieldMessageKey, EcliptixProtocolFailure> {
        guard keyMaterial.count == Constants.x25519KeySize else {
            return .failure(.invalidInput("Key material must be exactly \(Constants.x25519KeySize) bytes, but was \(keyMaterial.count)."))
        }

        do {
            let allocateResult = SodiumSecureMemoryHandle.allocate(length: Constants.x25519KeySize).mapSodiumFailure()
            
            if allocateResult.isErr {
                return .failure(try allocateResult.unwrapErr())
            }
            
            let keyHandle = try allocateResult.unwrap()
                    
            let writeResult = keyMaterial.withUnsafeBytes { bufferPointer in
                keyHandle.write(data: bufferPointer).mapSodiumFailure()
            }
            
            if writeResult.isErr {
                keyHandle.dispose()
                return .failure(try writeResult.unwrapErr())
            }
            
            let messageKey = ShieldMessageKey(index: index, keyHandle: keyHandle)
            return .success(messageKey)
        } catch {
            return .failure(.unexpectedError("Unexpected error occurred in \(String(describing: ShieldMessageKey.self))", inner: error))
        }
    }

    func readKeyMaterial(into destination: inout Data) -> Result<Unit, EcliptixProtocolFailure> {
        guard !disposed else {
            return .failure(.objectDisposed(String(describing: ShieldMessageKey.self)))
        }

        guard destination.count >= Constants.x25519KeySize else {
            return .failure(.bufferTooSmall("Destination buffer must be at least \(Constants.x25519KeySize) bytes, but was \(destination.count)."))
        }

        return destination.withUnsafeMutableBytes { destPtr in
            keyHandle.read(into: destPtr).mapSodiumFailure()
        }
    }

    func dispose() {
        dispose(disposing: true)
    }
    
    func dispose(disposing: Bool) {
        if !self.disposed {
            if disposing {
                keyHandle.dispose()
            }
            disposed = true
        }
    }

    static func == (lhs: ShieldMessageKey, rhs: ShieldMessageKey) -> Bool {
        return lhs.index == rhs.index && lhs.disposed == rhs.disposed
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(index)
    }
}
