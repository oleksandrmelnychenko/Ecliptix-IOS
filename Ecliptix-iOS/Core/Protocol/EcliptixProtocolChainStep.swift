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
    private static let okResult = Result<Unit, EcliptixProtocolFailure>.success(.value)

    private var chainKeyHandle: SodiumSecureMemoryHandle
    private var dhPrivateKeyHandle: SodiumSecureMemoryHandle?
    private var messageKeys: OrderedDictionary<UInt32, EcliptixMessageKey>
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
        self.chainKeyHandle = chainKeyHandle
        self.dhPrivateKeyHandle = dhPrivateKeyHandle
        self.dhPublicKey = dhPublicKey
        self.cacheWindow = cacheWindowSize
        self.currentIndex = 0
        self.isNewChain = false
        self.messageKeys = [:]
        self.disposed = false
    }

    deinit {
        dispose(disposing: false)
    }

    func dispose() {
        dispose(disposing: true)
    }
    
    func getCurrentIndex() -> Result<UInt32, EcliptixProtocolFailure> {
        return self.disposed
            ? .failure(.objectDisposed(String(describing: EcliptixProtocolChainStep.self)))
            : .success(self.currentIndex)
    }

    internal func setCurrentIndex(_ value: UInt32) -> Result<Unit, EcliptixProtocolFailure> {
        if self.disposed {
            return .failure(.objectDisposed(String(describing: EcliptixProtocolChainStep.self)))
        }
        
        if self.currentIndex != value {
            self.currentIndex = value
        }
        
        return .success(.value)
    }
    
    static func create(
        stepType: ChainStepType,
        initialChainKey: inout Data,
        initialDhPrivateKey: inout Data?,
        initialDhPublicKey: inout Data?,
        cacheWindowSize: UInt32 = defaultCacheWindowSize
    ) -> Result<EcliptixProtocolChainStep, EcliptixProtocolFailure> {
        
        return Result<Unit, EcliptixProtocolFailure>.success(.value)
            .flatMap { _ in validateInitialChainKey(initialChainKey) }
            .flatMap { _ in validateAndPrepareDhKeys(&initialDhPrivateKey, &initialDhPublicKey) }
            .flatMap { dhInfo in
                allocateAndWriteChainKey(&initialChainKey)
                    .flatMap { chainKeyHandle in
                        let actualCacheWindow: UInt32 = cacheWindowSize > 0 ? cacheWindowSize : Self.defaultCacheWindowSize
                        let step = EcliptixProtocolChainStep(
                            stepType: stepType,
                            chainKeyHandle: chainKeyHandle,
                            dhPrivateKeyHandle: dhInfo.dhPrivateKeyHandle,
                            dhPublicKey: &dhInfo.dhPublicKeyCloned,
                            cacheWindowSize: actualCacheWindow
                        )
                        return .success(step)
                    }
                    .mapError { err in
                        dhInfo.dhPrivateKeyHandle?.dispose()
                        _ = wipeIfNotNil(&dhInfo.dhPublicKeyCloned)
                        return err
                    }
            }
    }
    
    internal func getOrDeriveKeyFor(targetIndex: UInt32) -> Result<EcliptixMessageKey, EcliptixProtocolFailure> {
        if self.disposed {
            return .failure(.objectDisposed(String(describing: EcliptixProtocolChainStep.self)))
        }
        
        do {
            let cachedKey = self.messageKeys[targetIndex]
            
            if cachedKey != nil {
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
            
            let chainKeyResult = self.chainKeyHandle.readBytes(length: Constants.x25519KeySize).mapSodiumFailure()
            if chainKeyResult.isErr {
                return .failure(try chainKeyResult.unwrapErr())
            }
            
            var chainKey = try chainKeyResult.unwrap()
            
            defer {
                _ = Self.wipeIfNotNil(&chainKey)
            }
            
            var nextChainKey = Data(count: Constants.x25519KeySize)
            var msgKey = Data(count: Constants.aesKeySize)
            
            
            for idx in (currentIndex + 1)...targetIndex {
                do {
                    var saltHkdfMsg: Data? = nil
                    let hkdfMsg = try HkdfSha256(ikm: &chainKey, salt: &saltHkdfMsg)
                    try hkdfMsg.expand(info: Constants.msgInfo, output: &msgKey)

                    var saltHkdfChain: Data? = nil
                    let hkdfChain = try HkdfSha256(ikm: &chainKey, salt: &saltHkdfChain)
                    try hkdfChain.expand(info: Constants.chainInfo, output: &nextChainKey)
                } catch {
                    return .failure(.deriveKey("HKDF failed during derivation at index \(idx).", inner: error))
                }
                                
                let keyResult = EcliptixMessageKey.new(index: idx, keyMaterial: &msgKey)
                if keyResult.isErr {
                    return .failure(try keyResult.unwrapErr())
                }
                
                let messageKey = try keyResult.unwrap()
                                
                if self.messageKeys[idx] != nil {
                    messageKey.dispose()
                    return .failure(.generic("Key for index \(idx) unexpectedly appeared during derivation."))
                }
                self.messageKeys[idx] = messageKey
        
                let writeResult = nextChainKey.withUnsafeBytes { bufferPointer in
                    self.chainKeyHandle.write(data: bufferPointer).mapSodiumFailure()
                }

                if writeResult.isErr {
                    self.messageKeys.removeValue(forKey: idx)?.dispose()
                    return .failure(try writeResult.unwrapErr())
                }
                
                chainKey = nextChainKey
            }
            
            let setIndexResult = setCurrentIndex(targetIndex)
            if setIndexResult.isErr {
                return .failure(try setIndexResult.unwrapErr())
            }
            
            pruneOldKeys()
            
            if let finalKey = self.messageKeys[targetIndex] {
                return .success(finalKey)
            } else {
                return .failure(.generic("Derived key for index \(targetIndex) missing after derivation loop."))
            }
            
        } catch {
            return .failure(.generic("Error during get or derive key.", inner: error))
        }
    }
    
    public func skipKeysUntil(targetIndex: UInt32) -> Result<Unit, EcliptixProtocolFailure> {
        
        if self.currentIndex >= targetIndex {
            return .success(.value)
        }
        
        do {
            for i in (self.currentIndex + 1)...targetIndex {
                let keyResult = self.getOrDeriveKeyFor(targetIndex: i)
                guard keyResult.isOk else {
                    return .failure(try keyResult.unwrapErr())
                }
            }
        } catch {
            return .failure(.unexpectedError("Unhandled error during key derivation: \(error)"))
        }
        
        return self.setCurrentIndex(targetIndex)
    }
    
    internal func getDhPrivateKeyHandle() -> SodiumSecureMemoryHandle? {
        return self.dhPrivateKeyHandle
    }
    
    public func toProtoState() -> Result<Ecliptix_Proto_ChainStepState, EcliptixProtocolFailure> {
        guard !self.disposed else {
            return .failure(.objectDisposed(String(describing: EcliptixProtocolChainStep.self)))
        }
        
        do {
            let chainKey = try self.chainKeyHandle.readBytes(length: Constants.x25519KeySize).unwrap()
            let dhPrivKey = try self.dhPrivateKeyHandle?.readBytes(length: Constants.x25519PrivateKeySize).unwrap()
            
            var proto = Ecliptix_Proto_ChainStepState()
            proto.currentIndex = self.currentIndex
            proto.chainKey = chainKey
            
            if dhPrivKey != nil {
                proto.dhPrivateKey = dhPrivKey!
            }
            if self.dhPublicKey != nil {
                proto.dhPublicKey = self.dhPublicKey!
            }
            
            return .success(proto)
        } catch {
            return .failure(.generic("Failed to export chain step to proto state.", inner: error))
        }
    }
    
    public static func fromProtoState(stepType: ChainStepType, proto: Ecliptix_Proto_ChainStepState) -> Result<EcliptixProtocolChainStep, EcliptixProtocolFailure> {
        
        var chainKeyData = proto.chainKey
        var dhPrivKeyData: Data? = proto.dhPrivateKey
        var dhPublicKey: Data? = proto.dhPublicKey
        
        let createResult = Self.create(stepType: stepType, initialChainKey: &chainKeyData, initialDhPrivateKey: &dhPrivKeyData, initialDhPublicKey: &dhPublicKey)
        
        guard createResult.isErr else {
            return createResult
        }
        
        do {
            let chainStep = try createResult.unwrap()
            _ = try chainStep.setCurrentIndex(proto.currentIndex).unwrap()
            
            return .success(chainStep)
        } catch {
            return .failure(.unexpectedError("Unhandled error during desiralization of EcliptixProtocolChainStep: \(error)"))
        }
    }

    internal func updateKeysAfterDhRatchet(newChainKey: inout Data, newDhPrivateKey: inout Data?, newDhPublicKey: inout Data?) -> Result<Unit, EcliptixProtocolFailure> {
        
        return .success(.value)
            .flatMap { _ in checkDisposed() }
            .flatMap { _ in Self.validateNewChainKey(newChainKey) }
            .flatMap { _ in newChainKey.withUnsafeBytes { bufferPointer in
                    self.chainKeyHandle.write(data: bufferPointer).mapSodiumFailure()
                }
            }
            .flatMap { _ in setCurrentIndex(0) }
            .flatMap { _ in handleDhKeyUpdate(newDhPrivateKey: &newDhPrivateKey, newDhPublicKey: &newDhPublicKey) }
            .map { _ in
                self.isNewChain = self.stepType == .sender
                return .value
            }
    }
    
    func readDhPublicKey() -> Result<Data?, EcliptixProtocolFailure> {
        return checkDisposed().map { _ in
            let result = self.dhPublicKey
            return result
        }
    }
    
    internal func pruneOldKeys() {
        if disposed || cacheWindow == 0 || self.messageKeys.isEmpty { return }
        
        do {
            let currentIndexResult = getCurrentIndex()
            if currentIndexResult.isErr {
                return;
            }
            let indexToPruneAgainst: UInt32 = try currentIndexResult.unwrap()
            
            let minIndexToKeep = indexToPruneAgainst >= self.cacheWindow ? indexToPruneAgainst - self.cacheWindow + 1 : 0
                        
            let keysToRemove: [UInt32] = self.messageKeys.keys.filter { $0 < minIndexToKeep }
            
            for keyIndex in keysToRemove {
                if let messageKeyToDispose = self.messageKeys.removeValue(forKey: keyIndex) {
                    messageKeyToDispose.dispose()
                 }
            }
        }
        catch {
            return
        }
    }

    private static func validateInitialChainKey(_ initialChainKey: Data) -> Result<Unit, EcliptixProtocolFailure> {
        guard initialChainKey.count == Constants.x25519KeySize else {
            return .failure(.invalidInput("Initial chain key must be \(Constants.x25519KeySize) bytes."))
        }
        return .success(.value)
    }

    private static func validateAndPrepareDhKeys(_ initialDhPrivateKey: inout Data?, _ initialDhPublicKey: inout Data?) -> Result<DhKeyInfo, EcliptixProtocolFailure> {
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
            .flatMap { handle in
                dhPrivateKeyHandle = handle
                                
                return initialDhPrivateKey!.withUnsafeBytes { bufferPointer in
                    handle.write(data: bufferPointer).mapSodiumFailure()
                }
            }
            .map { _ in
                let dhPublicKeyCloned = initialDhPublicKey!
                
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
            .flatMap { handle in
                chainKeyHandle = handle
                
                return initialChainKey.withUnsafeBytes { bufferPointer in
                    handle.write(data: bufferPointer).mapSodiumFailure()
                }
            }
            .map { _ in chainKeyHandle! }
            .mapError { err in
                chainKeyHandle?.dispose()
                return err
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

    private static func validateNewChainKey(_ newChainKey: Data) -> Result<Unit, EcliptixProtocolFailure> {
        if newChainKey.count == Constants.x25519KeySize {
            return .success(.value)
        } else {
            return .failure(.invalidInput("New chain key must be \(Constants.x25519KeySize) bytes."))
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
    
    private func handleDhKeyUpdate(newDhPrivateKey: inout Data?, newDhPublicKey: inout Data?) -> Result<Unit, EcliptixProtocolFailure> {
        if newDhPrivateKey == nil && newDhPublicKey == nil {
            return Self.okResult
        }
        
        defer {
            _ = Self.wipeIfNotNil(&newDhPrivateKey)
            _ = Self.wipeIfNotNil(&newDhPublicKey)
        }
        
        let privateCopy = newDhPrivateKey
        let publicCopy = newDhPublicKey
        
        return EcliptixProtocolChainStep.validateAll(
            { EcliptixProtocolChainStep.validateDhKeysNotNull(privateKey: privateCopy, publicKey: publicCopy) },
            { EcliptixProtocolChainStep.validateDhPrivateKeySize(privateKey: privateCopy) },
            { EcliptixProtocolChainStep.validateDhPublicKeySize(publicKey: publicCopy) }
        ).flatMap { _ in
            let handleResult = ensureDhPrivateKeyHandle()
            if handleResult.isErr {
                return handleResult.mapError { err in
                    return err
                }
            }

            let writeResult = privateCopy!.withUnsafeBytes { bufferPointer in
                self.dhPrivateKeyHandle!.write(data: bufferPointer).mapSodiumFailure()
            }
            if writeResult.isErr {
                return writeResult.mapError { err in
                    return err
                }
            }

            _ = Self.wipeIfNotNil(&self.dhPublicKey)
            self.dhPublicKey = publicCopy!

            return Self.okResult
        }
    }
    
    private func checkDisposed() -> Result<Unit, EcliptixProtocolFailure> {
        if disposed {
            return .failure(.objectDisposed(String(describing: EcliptixProtocolChainStep.self)))
        } else {
            return .success(.value)
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
            return .failure(.generic("Failed to allocate memory for DH private key.", inner: error))
        }
    }
    
    private func dispose(disposing: Bool) {
        guard !disposed else { return }
        disposed = true

        chainKeyHandle.dispose()
        dhPrivateKeyHandle?.dispose()
        _ = Self.wipeIfNotNil(&dhPublicKey)

        dhPrivateKeyHandle = nil
        dhPublicKey = nil
    }

    private final class DhKeyInfo {
        var dhPrivateKeyHandle: SodiumSecureMemoryHandle?
        var dhPublicKeyCloned: Data?

        init(dhPrivateKeyHandle: SodiumSecureMemoryHandle?, dhPublicKeyCloned: Data?) {
            self.dhPrivateKeyHandle = dhPrivateKeyHandle
            self.dhPublicKeyCloned = dhPublicKeyCloned
        }
    }
}
