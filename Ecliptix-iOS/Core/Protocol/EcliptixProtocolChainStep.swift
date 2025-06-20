//
//  ShieldChainStep.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 26.05.2025.
//

import Foundation
import OrderedCollections

final class EcliptixProtocolChainStep {
    private static let defaultCacheWindowSize: UInt32 = 1000
    private static let okResult = Result<Unit, EcliptixProtocolFailure>.success(Unit())

    private var _chainKeyHandle: SodiumSecureMemoryHandle
    private var dhPrivateKeyHandle: SodiumSecureMemoryHandle?
    private var dhPublicKey: Data?
    private var currentIndex: UInt32 = 0
    private var isNewChain = false
    private let stepType: ChainStepType
    private let cacheWindow: UInt32
    
    private var disposed = false
    

    private init(
        stepType: ChainStepType,
        chainKeyHandle: SodiumSecureMemoryHandle,
        dhPrivateKeyHandle: SodiumSecureMemoryHandle?,
        dhPublicKey: inout Data?,
        cacheWindowSize: UInt32
    ) {
        self.stepType = stepType
        self._chainKeyHandle = chainKeyHandle
        self.dhPrivateKeyHandle = dhPrivateKeyHandle
        self.dhPublicKey = dhPublicKey
        self.cacheWindow = cacheWindowSize
        self.currentIndex = 0
        self.isNewChain = false
        self.disposed = false
        debugPrint("[ShieldChainStep] Created chain step of type \(stepType)")
    }

    deinit {
        dispose(disposing: false)
    }

    func dispose() {
        dispose(disposing: true)
    }
    
    func getCurrentIndex() -> Result<UInt32, EcliptixProtocolFailure> {
        return disposed
            ? .failure(.objectDisposed(String(describing: EcliptixProtocolChainStep.self)))
            : .success(currentIndex)
    }

    func setCurrentIndex(_ value: UInt32) -> Result<Unit, EcliptixProtocolFailure> {
        if disposed {
            return .failure(.objectDisposed(String(describing: EcliptixProtocolChainStep.self)))
        }
        
        if currentIndex != value {
            debugPrint("[ShieldChainStep] Setting current index from \(currentIndex) to \(value)")
            currentIndex = value
        }
        
        return .success(Unit.value)
    }
    
    func pruneOldKeys(messageKeys: inout OrderedDictionary<UInt32, EcliptixMessageKey>) {
        if disposed || cacheWindow == 0 || messageKeys.isEmpty { return }
        
        do {
            let currentIndexResult = getCurrentIndex()
            if currentIndexResult.isErr {
                return;
            }
            let indexToPruneAgainst: UInt32 = try currentIndexResult.unwrap()
            
            let minIndexToKeep: UInt32
            if indexToPruneAgainst >= cacheWindow {
                minIndexToKeep = indexToPruneAgainst - cacheWindow + 1
            } else {
                minIndexToKeep = 0
            }
            
            debugPrint("[ShieldChainStep] Pruning old keys. Current Index: \(indexToPruneAgainst), Min Index to Keep: \(minIndexToKeep)")
            
            // Find keys to remove (less than minIndexToKeep)
            let keysToRemove: [UInt32] = messageKeys.keys.filter { $0 < minIndexToKeep }
            
            for keyIndex in keysToRemove {
                if let messageKeyToDispose = messageKeys.removeValue(forKey: keyIndex) {
                    messageKeyToDispose.dispose()
                    debugPrint("[ShieldChainStep] Removed old key at index \(keyIndex)")
                }
            }
        }
        catch {
            debugPrint("[ShieldChainStep] Error during pruning old keys: \(error)")
            return
        }
    }
    
    private func dispose(disposing: Bool) {
        guard !disposed else { return }
        disposed = true
        debugPrint("[ShieldChainStep] Disposing chain step of type \(stepType)")

        _chainKeyHandle.dispose()
        dhPrivateKeyHandle?.dispose()
        _ = Self.wipeIfNotNil(&dhPublicKey)

        dhPrivateKeyHandle = nil
        dhPublicKey = nil
    }
    
    private static func wipeIfNotNil(_ data: inout Data?) -> Result<Unit, EcliptixProtocolFailure> {
        if data == nil {
            return .success(Unit.value)
        }
        else {
            return wipeIfNotNil(&data!)
        }
    }
    
    private static func wipeIfNotNil(_ data: inout Data) -> Result<Unit, EcliptixProtocolFailure> {
        return SodiumInterop.secureWipe(&data).mapSodiumFailure()
    }

    private final class DhKeyInfo {
        var dhPrivateKeyHandle: SodiumSecureMemoryHandle?
        var dhPublicKeyCloned: Data?

        init(dhPrivateKeyHandle: SodiumSecureMemoryHandle?, dhPublicKeyCloned: Data?) {
            self.dhPrivateKeyHandle = dhPrivateKeyHandle
            self.dhPublicKeyCloned = dhPublicKeyCloned
        }
    }
    
    static func create(
        stepType: ChainStepType,
        initialChainKey: inout Data,
        initialDhPrivateKey: inout Data?,
        initialDhPublicKey: inout Data?,
        cacheWindowSize: UInt32 = defaultCacheWindowSize
    ) -> Result<EcliptixProtocolChainStep, EcliptixProtocolFailure> {
        debugPrint("[ShieldChainStep] Creating chain step of type \(stepType)")

        return Result<Unit, EcliptixProtocolFailure>.success(Unit())
            .flatMap { _ in validateInitialChainKey(initialChainKey) }
            .flatMap { _ in validateAndPrepareDhKeys(&initialDhPrivateKey, &initialDhPublicKey) }
            .flatMap { dhInfo in
                allocateAndWriteChainKey(&initialChainKey)
                    .flatMap { chainKeyHandle in
                        let actualCacheWindow: UInt32 = cacheWindowSize > 0 ? cacheWindowSize : defaultCacheWindowSize
                        let step = EcliptixProtocolChainStep(
                            stepType: stepType,
                            chainKeyHandle: chainKeyHandle,
                            dhPrivateKeyHandle: dhInfo.dhPrivateKeyHandle,
                            dhPublicKey: &dhInfo.dhPublicKeyCloned,
                            cacheWindowSize: actualCacheWindow
                        )
                        debugPrint("[ShieldChainStep] Chain step created successfully.")
                        return .success(step)
                    }
                    .mapError { err in
                        debugPrint("[ShieldChainStep] Error creating chain step: \(err.message)")
                        dhInfo.dhPrivateKeyHandle?.dispose()
                        _ = wipeIfNotNil(&dhInfo.dhPublicKeyCloned)
                        return err
                    }
            }
    }

    private static func validateInitialChainKey(_ initialChainKey: Data) -> Result<Unit, EcliptixProtocolFailure> {
        guard initialChainKey.count == Constants.x25519KeySize else {
            return .failure(.invalidInput("Initial chain key must be \(Constants.x25519KeySize) bytes."))
        }
        return .success(Unit.value)
    }

    private static func validateAndPrepareDhKeys(
        _ initialDhPrivateKey: inout Data?,
        _ initialDhPublicKey: inout Data?
    ) -> Result<DhKeyInfo, EcliptixProtocolFailure> {
        debugPrint("[ShieldChainStep] Validating and preparing DH keys")
        if initialDhPrivateKey == nil && initialDhPublicKey == nil {
            return .success(DhKeyInfo(dhPrivateKeyHandle: nil, dhPublicKeyCloned: nil))
        }

        if initialDhPrivateKey == nil || initialDhPublicKey == nil {
            return .failure(.invalidInput("Both DH private and public keys must be provided, or neither."))
        }

        guard initialDhPrivateKey!.count == Constants.x25519PrivateKeySize else {
            return .failure(.invalidInput("Initial DH private key must be \(Constants.x25519PrivateKeySize) bytes."))
        }

        guard initialDhPublicKey!.count == Constants.x25519KeySize else {
            return .failure(.invalidInput("Initial DH public key must be \(Constants.x25519KeySize) bytes."))
        }

        var dhPrivateKeyHandle: SodiumSecureMemoryHandle?
        
        return SodiumSecureMemoryHandle.allocate(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
            .flatMap { handle -> Result<Unit, EcliptixProtocolFailure> in
                dhPrivateKeyHandle = handle
                debugPrint("[ShieldChainStep] Writing initial DH private key: \(initialDhPrivateKey!.hexEncodedString())")
                                
                return initialDhPrivateKey!.withUnsafeBytes { bufferPointer in
                    handle.write(data: bufferPointer).mapSodiumFailure()
                }
            }
            .map { _ in
                let dhPublicKeyCloned = initialDhPublicKey!
                debugPrint("[ShieldChainStep] Cloned DH public key: \(dhPublicKeyCloned.hexEncodedString())")
                return DhKeyInfo(dhPrivateKeyHandle: dhPrivateKeyHandle, dhPublicKeyCloned: dhPublicKeyCloned)
            }
            .mapError { err in
                dhPrivateKeyHandle?.dispose()
                return err
            }
    }
    
    private static func allocateAndWriteChainKey(_ initialChainKey: inout Data) -> Result<SodiumSecureMemoryHandle, EcliptixProtocolFailure> {
        var chainKeyHandle: SodiumSecureMemoryHandle? = nil

        return SodiumSecureMemoryHandle.allocate(length: Constants.x25519KeySize).mapSodiumFailure()
            .flatMap { handle -> Result<Unit, EcliptixProtocolFailure> in
                chainKeyHandle = handle
                debugPrint("[ShieldChainStep] Writing initial chain key: \(initialChainKey.hexEncodedString())")
                return initialChainKey.withUnsafeBytes { bufferPointer in
                    handle.write(data: bufferPointer).mapSodiumFailure()
                }
            }
            .map { _ in chainKeyHandle! }
            .mapError { err in
                debugPrint("[ShieldChainStep] Error allocating chain key: \(err.message)")
                chainKeyHandle?.dispose()
                return err
            }
    }

    func getOrDeriveKeyFor(targetIndex: UInt32, messageKeys: inout OrderedDictionary<UInt32, EcliptixMessageKey>) -> Result<EcliptixMessageKey, EcliptixProtocolFailure> {
        if disposed {
            return .failure(.objectDisposed(String(describing: EcliptixProtocolChainStep.self)))
        }

        var chainKey: Data?
        
        defer {
            _ = Self.wipeIfNotNil(&chainKey)
        }
        
        do {
            let cachedKey = messageKeys[targetIndex]
            
            if cachedKey != nil {
                debugPrint("[ShieldChainStep] Returning cached key for index \(targetIndex)")
                return .success(cachedKey!)
            }

            let currentIndexResult = getCurrentIndex()
            if currentIndexResult.isErr {
                return .failure(try currentIndexResult.unwrapErr())
            }
            
            let currentIndex = try currentIndexResult.unwrap()
            
            if targetIndex <= currentIndex {
                return .failure(.invalidInput("[\(stepType)] Requested index \(targetIndex) is not future (current: \(currentIndex)) and not cached."))
            }
            
            debugPrint("[ShieldChainStep] Starting derivation for target index: \(targetIndex), current index: \(currentIndex)")

            let chainKeyResult = _chainKeyHandle.readBytes(length: Constants.x25519KeySize).mapSodiumFailure()
            if chainKeyResult.isErr {
                return .failure(try chainKeyResult.unwrapErr())
            }
            
            chainKey = try chainKeyResult.unwrap()
            
            var currentChainKey = Data(count: Constants.x25519KeySize)
            var nextChainKey = Data(count: Constants.x25519KeySize)
            var msgKey = Data(count: Constants.aesKeySize)
            
            currentChainKey.replaceSubrange(0..<Constants.x25519KeySize, with: chainKey!)
            
            for idx in (currentIndex + 1)...targetIndex {
                debugPrint("[ShieldChainStep] Deriving key for index: \(idx)")
                
                do {
                    var saltHkdfMsg: Data? = nil
                    let hkdfMsg = try HkdfSha256(ikm: &currentChainKey, salt: &saltHkdfMsg)
                    try hkdfMsg.expand(info: Constants.msgInfo, output: &msgKey)

                    var saltHkdfChain: Data? = nil
                    let hkdfChain = try HkdfSha256(ikm: &currentChainKey, salt: &saltHkdfChain)
                    try hkdfChain.expand(info: Constants.chainInfo, output: &nextChainKey)
                } catch {
                    debugPrint("[ShieldChainStep] Error deriving keys at index \(idx): \(error)")
                    return .failure(.deriveKey("HKDF failed during derivation at index \(idx).", inner: error))
                }
                
//                var msgKeyClone = msgKey
                
                let keyResult = EcliptixMessageKey.new(index: idx, keyMaterial: &msgKey)
                if keyResult.isErr {
                    return .failure(try keyResult.unwrapErr())
                }
                
                let messageKey = try keyResult.unwrap()
                                
                if messageKeys[idx] != nil {
                    messageKey.dispose()
                    return .failure(.generic("Key for index \(idx) unexpectedly appeared during derivation."))
                }
                messageKeys[idx] = messageKey
        
                let writeResult = nextChainKey.withUnsafeBytes { bufferPointer in
                    _chainKeyHandle.write(data: bufferPointer)
                }.mapSodiumFailure()

                if writeResult.isErr {
                    messageKeys.removeValue(forKey: idx)?.dispose()
                    return .failure(try writeResult.unwrapErr())
                }
                
                currentChainKey.replaceSubrange(0..<Constants.x25519KeySize, with: nextChainKey)
            }
            
            let setIndexResult = setCurrentIndex(targetIndex)
            if setIndexResult.isErr {
                return .failure(try setIndexResult.unwrapErr())
            }
            
            pruneOldKeys(messageKeys: &messageKeys)
            
            if let finalKey = messageKeys[targetIndex] {
                debugPrint("[ShieldChainStep] Derived key for index \(targetIndex) successfully.")
                return .success(finalKey)
            } else {
                debugPrint("[ShieldChainStep] Derived key for index \(targetIndex) not found in cache.")
                return .failure(.generic("Derived key for index \(targetIndex) missing after derivation loop."))
            }
            
        } catch {
            debugPrint("[ShieldChainStep] Error during get or derive key: \(error)")
            return .failure(.generic("Error during get or derive key.", inner: error))
        }
    }

    func updateKeysAfterDhRatchet(newChainKey: inout Data, newDhPrivateKey: inout Data?, newDhPublicKey: inout Data?) -> Result<Unit, EcliptixProtocolFailure> {
        debugPrint("[ShieldChainStep] Updating keys after DH ratchet for \(stepType)")
        
        return .success(Unit())
            .flatMap { _ in checkDisposed() }
            .flatMap { _ in Self.validateNewChainKey(newChainKey) }
//            .flatMap { _ in
//                debugPrint("[ShieldChainStep] Writing new chain key: \(newChainKey.hexEncodedString())")
//                return newChainKey.withUnsafeBytes { bufferPointer in
//                    _chainKeyHandle.write(data: bufferPointer).mapSodiumFailure()
//                }
//            }
            .flatMap { _ in newChainKey.withUnsafeBytes { bufferPointer in
                    self._chainKeyHandle.write(data: bufferPointer).mapSodiumFailure()
                }
            }
            .flatMap { _ in setCurrentIndex(0) }
            .flatMap { _ in handleDhKeyUpdate(newDhPrivateKey: &newDhPrivateKey, newDhPublicKey: &newDhPublicKey) }
            .map { _ in
                isNewChain = stepType == .sender
                debugPrint("[ShieldChainStep] Keys updated successfully. IsNewChain: \(self.isNewChain)")
                return .value
            }
    }
    
    
    private func handleDhKeyUpdate(newDhPrivateKey: inout Data?, newDhPublicKey: inout Data?) -> Result<Unit, EcliptixProtocolFailure> {
        if newDhPrivateKey == nil && newDhPublicKey == nil {
            return Self.okResult
        }

        var privateKey = newDhPrivateKey
        var publicKey = newDhPublicKey
        
        defer {
            _ = Self.wipeIfNotNil(&privateKey)
            _ = Self.wipeIfNotNil(&publicKey)
        }
        
        return EcliptixProtocolChainStep.validateAll(
            { EcliptixProtocolChainStep.validateDhKeysNotNull(privateKey: privateKey, publicKey: publicKey) },
            { EcliptixProtocolChainStep.validateDhPrivateKeySize(privateKey: privateKey) },
            { EcliptixProtocolChainStep.validateDhPublicKeySize(publicKey: publicKey) }
        ).flatMap { _ in
            print("[ShieldChainStep] Updating DH keys.")

            let handleResult = ensureDhPrivateKeyHandle()
            if handleResult.isErr {
                return handleResult.mapError { err in
                    return err
                }
            }

            let writeResult = newDhPrivateKey!.withUnsafeBytes { bufferPointer in
                dhPrivateKeyHandle!.write(data: bufferPointer).mapSodiumFailure()
            }
            if writeResult.isErr {
                return writeResult.mapError { err in
                    return err
                }
            }

            _ = Self.wipeIfNotNil(&dhPublicKey)
            dhPublicKey = newDhPublicKey!

            return Self.okResult
        }
    }
    
    private static func validateAll(_ validators: (() -> Result<Unit, EcliptixProtocolFailure>)?...) -> Result<Unit, EcliptixProtocolFailure> {
        let nonNilValidators = validators.compactMap { $0 }
        if nonNilValidators.isEmpty {
            return okResult
        }

        for validate in nonNilValidators {
            let result = validate()
            if case .failure(_) = result {
                return result
            }
        }

        return okResult
    }

    
    private func checkDisposed() -> Result<Unit, EcliptixProtocolFailure> {
        if disposed {
            return .failure(.objectDisposed(String(describing: EcliptixProtocolChainStep.self)))
        } else {
            return .success(.value)
        }
    }

    private static func validateNewChainKey(_ newChainKey: Data) -> Result<Unit, EcliptixProtocolFailure> {
        if newChainKey.count == Constants.x25519KeySize {
            return .success(.value)
        } else {
            return .failure(.invalidInput("New chain key must be \(Constants.x25519KeySize) bytes."))
        }
    }
    
    private func ensureDhPrivateKeyHandle() -> Result<Unit, EcliptixProtocolFailure> {
        if dhPrivateKeyHandle != nil {
            return EcliptixProtocolChainStep.okResult
        }

        do {
            let allocResult = SodiumSecureMemoryHandle.allocate(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
            if allocResult.isErr {
                return .failure(try allocResult.unwrapErr())
            }
            
            dhPrivateKeyHandle = try allocResult.unwrap()
            return Self.okResult
        } catch {
            debugPrint("[ShieldChainStep] Error during get or derive key: \(error)")
            return .failure(.generic("Failed to allocate memory for DH private key.", inner: error))
        }
    }
    
    private static func validateDhKeysNotNull(privateKey: Data?, publicKey: Data?) -> Result<Unit, EcliptixProtocolFailure> {
        if privateKey == nil && publicKey == nil {
            return okResult
        }

        if privateKey == nil || publicKey == nil {
            return .failure(.invalidInput("Both DH private and public keys must be provided together."))
        }

        return okResult
    }
    
    private static func validateDhPrivateKeySize(privateKey: Data?) -> Result<Unit, EcliptixProtocolFailure> {
        if privateKey == nil {
            return okResult
        }

        return privateKey!.count == Constants.x25519PrivateKeySize
            ? okResult
            : .failure(.invalidInput("DH private key must be \(Constants.x25519PrivateKeySize) bytes."))
    }
    
    private static func validateDhPublicKeySize(publicKey: Data?) -> Result<Unit, EcliptixProtocolFailure> {
        if publicKey == nil {
            return okResult
        }

        return publicKey!.count == Constants.x25519KeySize
            ? okResult
            : .failure(.invalidInput("DH public key must be \(Constants.x25519KeySize) bytes."))
    }

    func readDhPublicKey() -> Result<Data?, EcliptixProtocolFailure> {
        return checkDisposed().map { _ in
            let result = dhPublicKey
            debugPrint("[ShieldChainStep] Read DH public key: \(result?.hexEncodedString() ?? "nil")")
            return result
        }
    }
}
