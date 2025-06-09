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
    private var ikm: Data
    private var salt: Data
    private var disposed = false
    private let sodium: Sodium
    
    public init(ikm: inout Data, salt: inout Data?) throws {
        SodiumInterop.sodium_init()
        sodium = Sodium()
        self.ikm = ikm
        
        if salt == nil || (salt != nil && salt!.isEmpty) {
            self.salt = Data(count: Self.hashOutputLength)
        }
        else {
            if salt!.count != Self.hashOutputLength {
                throw HkdfError.invalidSaltLength(hashOutputLength: Self.hashOutputLength)
            }
            
            self.salt = salt!
        }
        
        disposed = false
    }
    
    public func dispose() {
        dispose(true)
    }
    
    public func expand(info: Data, output: inout Data) throws {
        guard !disposed else { throw HkdfError.disposed }
        guard output.count <= 255 * Self.hashOutputLength else {
            throw HkdfError.outputLengthTooLarge
        }

        var prk: Data = Data()
        
        do {
            
            var prkBytes = signHmacSha256(ikm: &ikm, salt: &salt)
            if prkBytes.count != Self.hashOutputLength {
                throw HkdfError.hmacOutputSizeMismatch
            }
            prk = Data(count: prkBytes.count)
            prk.replaceSubrange(0..<prkBytes.count, with: prkBytes)
            wipe(&prkBytes)
        } catch {
            throw HkdfError.hkdfExtractFailed(error)
        }
        
        var counter: UInt8 = 1
        var bytesWritten = 0
        var requiredInputSize = Self.hashOutputLength + info.count + 1
        
        var inputBufferHeap = Data(count: requiredInputSize)
        var inputBufferSpan = inputBufferHeap
        var hash = Data(count: Self.hashOutputLength)
        
        var prkAsKey = Data(count: Self.hashOutputLength)
        var tempInputArray: Data?
        
        defer {
            prk.removeAll()
            hash.removeAll()
            
            wipe(&inputBufferHeap)
            wipe(&prkAsKey)
            if tempInputArray != nil {
                wipe(&tempInputArray!)
            }
        }
        
        do {
            prkAsKey.replaceSubrange(0..<prk.count, with: prk)
            
            while bytesWritten < output.count {
                var currentInputSlice: Data
                
                if bytesWritten == 0 {
                    inputBufferSpan.replaceSubrange(0..<info.count, with: info)
                    inputBufferSpan[info.count] = counter
                    currentInputSlice = inputBufferSpan[0..<info.count + 1]
                }
                else {
                    inputBufferSpan.replaceSubrange(0..<hash.count, with: hash)
                    inputBufferSpan.replaceSubrange(Self.hashOutputLength..<(Self.hashOutputLength + info.count), with: info)
                    inputBufferSpan[Self.hashOutputLength + info.count] = counter
                    currentInputSlice = inputBufferSpan[0..<(Self.hashOutputLength + info.count + 1)]
                }
                
                if tempInputArray == nil || tempInputArray!.count != currentInputSlice.count {
                    tempInputArray = Data(count: currentInputSlice.count)
                }
                
                tempInputArray?.replaceSubrange(0..<currentInputSlice.count, with: currentInputSlice)
                
                var tempHashResult = signHmacSha256(ikm: &tempInputArray!, salt: &prkAsKey)
                
                if tempHashResult.count != Self.hashOutputLength {
                    throw HkdfError.hmacOutputSizeMismatch
                }
                
                hash.replaceSubrange(0..<tempHashResult.count, with: tempHashResult)
                wipe(&tempHashResult)
                
                let bytesToCopy = min(Self.hashOutputLength, output.count - bytesWritten)
                output.replaceSubrange(bytesWritten..<(bytesWritten + bytesToCopy), with: hash.prefix(bytesToCopy))

                bytesWritten += bytesToCopy
                counter += 1
                wipe(&tempInputArray!)
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
                wipe(&ikm)
                wipe(&salt)
            }
            disposed = true
        }
    }

    deinit {
        dispose()
    }

    private func wipe(_ data: inout Data) {
        _ = SodiumInterop.secureWipe(&data)
    }
}

private extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}
