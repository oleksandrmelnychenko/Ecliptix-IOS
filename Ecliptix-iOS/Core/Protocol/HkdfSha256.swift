//
//  HkdfSha256.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 23.05.2025.
//

import Foundation
import Sodium
import Clibsodium

enum HkdfError: LocalizedError, Equatable {
    case invalidSaltLength(hashOutputLength: Int)
    case hmacOutputSizeMismatch
    case hkdfExtractFailed(Error)
    case hmacGenerationFailed(counter: UInt32)
    case outputLengthTooLarge
    case disposed
    
    var errorDescription: String? {
        switch self {
        case .invalidSaltLength(let hashOutputLength):
            return "Salt must be \(hashOutputLength) bytes for HMAC-SHA256."
        case .hmacOutputSizeMismatch:
            return "HMAC-SHA256 output size mismatch during PRK generation."
        case .hkdfExtractFailed(let error):
            return "HKDF-Extract failed: \(error.localizedDescription)"
        case .hmacGenerationFailed(let counter):
            return "HMAC-SHA256 failed to generate block for counter \(counter)."
        case .outputLengthTooLarge:
            return "Output length too large."
        case .disposed:
            return "HkdfSha256 has already been disposed."
        }
    }
    
    static func == (lhs: HkdfError, rhs: HkdfError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidSaltLength(let l), .invalidSaltLength(let r)):
            return l == r
        case (.hmacOutputSizeMismatch, .hmacOutputSizeMismatch):
            return true
        case (.hkdfExtractFailed, .hkdfExtractFailed):
            return true
        case (.hmacGenerationFailed(let l), .hmacGenerationFailed(let r)):
            return l == r
        case (.outputLengthTooLarge, .outputLengthTooLarge):
            return true
        case (.disposed, .disposed):
            return true
        default:
            return false
        }
    }

}

public final class HkdfSha256 {
    private static let hashOutputLength = 32
    private let ikmHandle: SodiumSecureMemoryHandle
    private var saltHandle: SodiumSecureMemoryHandle
    private var disposed = false
    
    public init(ikm: inout Data, salt: inout Data?) throws {
        let ikmHandle = try SodiumSecureMemoryHandle.allocate(length: ikm.count).unwrap()
        _ = ikm.withUnsafeBytes { bufferPointer in
            ikmHandle.write(data: bufferPointer)
        }

        let saltHandle: SodiumSecureMemoryHandle
        if salt == nil || salt!.isEmpty {
            saltHandle = try SodiumSecureMemoryHandle.allocate(length: Self.hashOutputLength).unwrap()
        } else {
            guard salt!.count == Self.hashOutputLength else {
                throw HkdfError.invalidSaltLength(hashOutputLength: Self.hashOutputLength)
            }
            saltHandle = try SodiumSecureMemoryHandle.allocate(length: salt!.count).unwrap()
            _ = salt!.withUnsafeBytes { bufferPointer in
                saltHandle.write(data: bufferPointer).mapSodiumFailure()
            }
        }

        self.ikmHandle = ikmHandle
        self.saltHandle = saltHandle
        self.disposed = false
    }
    
    deinit {
        dispose()
    }
    
    public func dispose() {
        dispose(true)
    }
    
    public func expand(info: Data, output: inout Data) throws {
        guard !disposed else { throw HkdfError.disposed }
        guard output.count <= 255 * Self.hashOutputLength else {
            throw HkdfError.outputLengthTooLarge
        }
        if output.isEmpty {
            return
        }

        var prk: Data = Data(count: Self.hashOutputLength)
        var ikmBytes: Data?
        var saltBytes: Data?
        
        defer {
            _ = SodiumInterop.secureWipe(&ikmBytes)
            _ = SodiumInterop.secureWipe(&saltBytes)
        }
        
        do {
            ikmBytes = try self.ikmHandle.readBytes(length: self.ikmHandle.length).unwrap()
            saltBytes = try self.saltHandle.readBytes(length: self.saltHandle.length).unwrap()
            var prkBytes = signHmacSha256(ikm: &ikmBytes!, salt: &saltBytes!)
            if prkBytes.count != Self.hashOutputLength {
                throw HkdfError.hmacOutputSizeMismatch
            }
            prk = Data(count: prkBytes.count)
            prk.replaceSubrange(0..<prkBytes.count, with: prkBytes)
            _ = SodiumInterop.secureWipe(&prkBytes)
            
        } catch {
            throw HkdfError.hkdfExtractFailed(error)
        }
        
        var counter: UInt32 = 1
        var bytesWritten = 0
        var previousHash = Data(count: Self.hashOutputLength)
        
        let hmacInputSize = Self.hashOutputLength + info.count + 1
        var hmacInputBuffer: Data?
        
        defer {
            prk.resetBytes(in: 0..<prk.count)
            prk.removeAll()
            previousHash.resetBytes(in: 0..<previousHash.count)
            previousHash.removeAll()
            
            if hmacInputBuffer != nil {
                hmacInputBuffer!.resetBytes(in: 0..<hmacInputBuffer!.count)
                hmacInputBuffer!.removeAll()
            }
        }
        
        do {
            hmacInputBuffer = Data(count: hmacInputSize)
            
            while bytesWritten < output.count {
                var currentInputLength = 0
                
                if bytesWritten == 0 {
                    hmacInputBuffer!.replaceSubrange(0..<info.count, with: info)
                    hmacInputBuffer![info.count] = UInt8(counter)
                    currentInputLength = info.count + 1
                } else {
                    hmacInputBuffer!.replaceSubrange(0..<Self.hashOutputLength, with: previousHash)
                    hmacInputBuffer!.replaceSubrange(Self.hashOutputLength..<(Self.hashOutputLength + info.count), with: info)
                    hmacInputBuffer![Self.hashOutputLength + info.count] = UInt8(counter)
                    currentInputLength = Self.hashOutputLength + info.count + 1
                }
                
                var inputSlice = hmacInputBuffer!.prefix(currentInputLength)
                var tempHashResult = signHmacSha256(ikm: &inputSlice, salt: &prk)
                
                let bytesToCopy = min(Self.hashOutputLength, output.count - bytesWritten)
                output.replaceSubrange(bytesWritten..<bytesWritten + bytesToCopy, with: tempHashResult.prefix(bytesToCopy))
                bytesWritten = bytesWritten + bytesToCopy
                
                if bytesWritten < output.count {
                    previousHash.replaceSubrange(0..<tempHashResult.count, with: tempHashResult)
                }
                
                _ = SodiumInterop.secureWipe(&tempHashResult)
                counter += 1
            }
        } catch {
            debugPrint("[HkdfSha256] Error expanding HKDF: \(error)")
            return
        }
    }
    
    private func signHmacSha256(ikm: inout Data, salt: inout Data) -> Data {
        guard SodiumInterop.sodium_init() >= 0 else {
            return Data()
        }
        
        var out = [UInt8](repeating: 0, count: Int(crypto_auth_hmacsha256_BYTES))
        
        let result = salt.withUnsafeBytes { saltPtr in
            ikm.withUnsafeBytes { ikmPtr in
                crypto_auth_hmacsha256(
                    &out,
                    ikmPtr.bindMemory(to: UInt8.self).baseAddress!,
                    UInt64(ikm.count),
                    saltPtr.bindMemory(to: UInt8.self).baseAddress!
                )
            }
        }
        
        return result == 0 ? Data(out) : Data()
    }

    private func dispose(_ disposing: Bool) {
        if !disposed {
            if disposing {
                self.ikmHandle.dispose()
                self.saltHandle.dispose()
            }
            disposed = true
        }
    }
}

private extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}
