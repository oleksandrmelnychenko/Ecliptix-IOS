//
//  ConnectSession.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 26.05.2025.
//

import Foundation
import CryptoKit
import OrderedCollections
import Sodium
import Atomics

enum EcliptixProtocolConnectionExceptions: Error {
    case ArgumentNil(message: String)
}

final class EcliptixProtocolConnection {
    
    private static let dhRotationInterval = 10
    private static let aesGcmNonceSize = 12
    private static let sessionTimeout: TimeInterval = 24 * 60 * 60 // 24 hours
    private static let initialSenderChainInfo = "ShieldInitSend".data(using: .utf8)!
    private static let initialReceiverChainInfo = "ShieldInitRecv".data(using: .utf8)!
    private static let dhRatchetInfo = "ShieldDhRatchet".data(using: .utf8)!
    private let lock = NSLock()
    private let createdAt: Date
    
    private let id: UInt32
    private var isFirstReceivingRatchet: Bool
    private let isInitiator: Bool
    private var messageKeys: OrderedDictionary<UInt32, EcliptixMessageKey>
    private let sendingStep: EcliptixProtocolChainStep
    private var currentSendingDhPrivateKeyHandle: SodiumSecureMemoryHandle?
    private let initialSendingDhPrivateKeyHandle: SodiumSecureMemoryHandle?
    private let nonceCounter = ManagedAtomic<UInt32>(0)
    private var peerBundle: LocalPublicKeyBundle?
    private var peerDhPublicKey: Data?
    private let persistentDhPrivateKeyHandle: SodiumSecureMemoryHandle?
    private var persistentDhPublicKey: Data?
    private var receivedNewDhKey: Bool
    private var receivingStep: EcliptixProtocolChainStep?
    private var rootKeyHandle: SodiumSecureMemoryHandle?
    
    
    public var disposed = false
    
    init(
        id: UInt32,
        isInitiator: Bool,
        initialSendingDhPrivateHandle: SodiumSecureMemoryHandle,
        sendingStep: EcliptixProtocolChainStep,
        persistentDhPrivateKeyHandle: SodiumSecureMemoryHandle,
        persistentDhPublicKey: Data) {
        
        self.id = id
        self.isInitiator = isInitiator
        self.initialSendingDhPrivateKeyHandle = initialSendingDhPrivateHandle
        self.currentSendingDhPrivateKeyHandle = initialSendingDhPrivateHandle
        self.sendingStep = sendingStep
        self.persistentDhPrivateKeyHandle = persistentDhPrivateKeyHandle
        self.persistentDhPublicKey = persistentDhPublicKey
        
        self.peerBundle = nil
        self.receivingStep = nil
        self.rootKeyHandle = nil
        self.messageKeys = [:]
        self.createdAt = Date()
        self.peerDhPublicKey = nil
        self.receivedNewDhKey = false
        self.isFirstReceivingRatchet = true
        
        debugPrint("[ShieldSession] Created session \(id), Initiator: \(isInitiator)")
    }
    
    deinit {
        dispose()
    }
    
    public func dispose() {
        dispose(disposing: true)
    }
    
    static func create(connectId: UInt32, isInitiator: Bool) -> Result<EcliptixProtocolConnection, EcliptixProtocolFailure> {
        var initialSendingDhPrivateKeyHandle: SodiumSecureMemoryHandle? = nil
        var initialSendingDhPublicKey: Data? = nil
        var initialSendingDhPrivateKeyBytes: Data? = nil
        var sendingStep: EcliptixProtocolChainStep? = nil
        var persistentDhPrivateKeyHandle: SodiumSecureMemoryHandle? = nil
        var persistentDhPublicKey: Data? = nil

        do {
            debugPrint("[ShieldSession] Creating session \(connectId), Initiator: \(isInitiator)")

            let overallResult = SodiumInterop.generateX25519KeyPair(keyPurpose: "Initial Sending DH")
                .flatMap { initialSendKeys -> Result<Unit, EcliptixProtocolFailure> in
                    initialSendingDhPrivateKeyHandle = initialSendKeys.0
                    initialSendingDhPublicKey = initialSendKeys.1
                    
                    debugPrint("[ShieldSession] Generated Initial Sending DH Public Key: \(initialSendingDhPublicKey!.hexEncodedString())")
                
                    return initialSendingDhPrivateKeyHandle!.readBytes(length: Constants.x25519PrivateKeySize)
                        .mapSodiumFailure()
                        .map { bytes in
                            initialSendingDhPrivateKeyBytes = Data(bytes)
                            debugPrint("[ShieldSession] Initial Sending DH Private Key: \(initialSendingDhPrivateKeyBytes!.hexEncodedString())")
                            return .value
                        }
                }
                .flatMap { _ in SodiumInterop.generateX25519KeyPair(keyPurpose: "Persistent DH")
                }
                .flatMap { persistentKeys -> Result<EcliptixProtocolChainStep, EcliptixProtocolFailure> in
                    persistentDhPrivateKeyHandle = persistentKeys.skHandle
                    persistentDhPublicKey = persistentKeys.pk
                    
                    debugPrint("[ShieldSession] Generated Persistent DH Public Key: \(persistentDhPublicKey!.hexEncodedString())")

                    var tempChainKey: Data? = Data(count: Constants.x25519KeySize)
                    let stepResult = EcliptixProtocolChainStep.create(
                        stepType: .sender,
                        initialChainKey: &tempChainKey!,
                        initialDhPrivateKey: &initialSendingDhPrivateKeyBytes,
                        initialDhPublicKey: &initialSendingDhPublicKey
                    )
                    _ = Self.wipeIfNotNil(&tempChainKey)
                    _ = Self.wipeIfNotNil(&initialSendingDhPrivateKeyBytes)
                    initialSendingDhPrivateKeyBytes = nil
            
                    return stepResult
                }
                .flatMap { createdSendingStep in
                    sendingStep = createdSendingStep
                    debugPrint("[ShieldSession] Sending step created for session \(connectId)")

                    let session = EcliptixProtocolConnection(
                        id: connectId,
                        isInitiator: isInitiator,
                        initialSendingDhPrivateHandle: initialSendingDhPrivateKeyHandle!,
                        sendingStep: sendingStep!,
                        persistentDhPrivateKeyHandle: persistentDhPrivateKeyHandle!,
                        persistentDhPublicKey: persistentDhPublicKey!
                    )

                    initialSendingDhPrivateKeyHandle = nil
                    persistentDhPrivateKeyHandle = nil
                    sendingStep = nil

                    return .success(session)
                }

            if overallResult.isErr {
                debugPrint("[ShieldSession] Failed to create session \(connectId): \(try overallResult.unwrapErr().message)")
                initialSendingDhPrivateKeyHandle?.dispose()
                sendingStep?.dispose()
                persistentDhPrivateKeyHandle?.dispose()
                _ = wipeIfNotNil(&initialSendingDhPrivateKeyBytes)
            }
            
            return overallResult

        } catch {
            debugPrint("[ShieldSession] Unexpected error creating session \(connectId): \(error.localizedDescription)")
            initialSendingDhPrivateKeyHandle?.dispose()
            sendingStep?.dispose()
            persistentDhPrivateKeyHandle?.dispose()
            _ = wipeIfNotNil(&initialSendingDhPrivateKeyBytes)
            return .failure(EcliptixProtocolFailure.generic("Unexpected error creating session \(connectId).", inner: error))
        }
    }
    
    public func getPeerBundle() -> Result<LocalPublicKeyBundle, EcliptixProtocolFailure> {
        lock.lock()
        defer { lock.unlock() }
        
        return checkDisposed().flatMap { _ in
            return peerBundle != nil
            ? .success(peerBundle!)
            : .failure(.generic("Peer bundle has not been set."))
        }
    }
    
    public func getIsInitiator() -> Result<Bool, EcliptixProtocolFailure> {
        return checkDisposed().map { _ in
            return isInitiator
        }
    }
    
    internal func setConnectionState(_ newState: Ecliptix_Proto_PubKeyExchangeState) -> Result<Unit, EcliptixProtocolFailure> {
        lock.lock()
        defer { lock.unlock() }
        
        return checkDisposed().map { u in
            debugPrint("[ShieldSession] Setting state for session \(id) to \(newState)")
            return u
        }
    }
    
    internal func setPeerBundle(_ peerBundleToSet: LocalPublicKeyBundle?) -> Result<Unit, EcliptixProtocolFailure> {
        lock.lock()
        defer { lock.unlock() }
        
        return checkDisposed().flatMap { _ in
            self.peerBundle = peerBundleToSet
            
            return .success(.value)
        }
    }
    
    internal func finalizeChainAndDhKeys(initialRootKey: inout Data, initialPeerDhPublicKey: inout Data) -> Result<Unit, EcliptixProtocolFailure> {
        
        lock.lock()
        
        var tempRootHandle: SodiumSecureMemoryHandle? = nil

        var localSenderCk: Data? = nil
        var localReceiverCk: Data? = nil
        var peerDhPublicCopy: Data? = nil
        var persistentPrivKeyBytes: Data? = nil

        defer {
            if localSenderCk != nil {
                localSenderCk!.resetBytes(in: 0...localSenderCk!.count)
                localSenderCk!.removeAll()
            }
            if localReceiverCk != nil {
                localReceiverCk!.resetBytes(in: 0...localReceiverCk!.count)
                localReceiverCk!.removeAll()
            }
            
            _ = Self.wipeIfNotNil(&peerDhPublicCopy)
            _ = Self.wipeIfNotNil(&persistentPrivKeyBytes)
            lock.unlock()
        }

        debugPrint("[ShieldSession] Finalizing chain and DH keys for session \(id)")

        return checkDisposed()
            .flatMap { _ -> Result<Unit, EcliptixProtocolFailure> in
                return checkIfNotFinalized()
            }
            .flatMap { _ -> Result<Unit, EcliptixProtocolFailure> in
                return Self.validateInitialKeys(rootKey: initialRootKey, peerDhKey: initialPeerDhPublicKey)
            }
            .flatMap { _ -> Result<Unit, EcliptixProtocolFailure> in
                peerDhPublicCopy = initialPeerDhPublicKey

                let result = SodiumSecureMemoryHandle.allocate(length: Constants.x25519KeySize)
                    .mapSodiumFailure()
                    .flatMap { handle -> Result<Unit, EcliptixProtocolFailure> in
                        tempRootHandle = handle
                        
                        return initialRootKey.withUnsafeBytes { bufferPointer in
                            handle.write(data: bufferPointer).mapSodiumFailure()
                        }
                    }
                
                return result
            }
            .flatMap { _ -> Result<Unit, EcliptixProtocolFailure> in
                localSenderCk = Data(count: Constants.x25519KeySize)
                localReceiverCk = Data(count: Constants.x25519KeySize)
                return deriveInitialChainKeys(rootKey: &initialRootKey, senderCkDest: &localSenderCk!, receiverCkDest: &localReceiverCk!)
            }
            .flatMap { _ -> Result<Unit, EcliptixProtocolFailure> in
                return persistentDhPrivateKeyHandle!.readBytes(length: Constants.x25519PrivateKeySize)
                    .mapSodiumFailure()
                    .map { bytes -> Unit in
                        persistentPrivKeyBytes = bytes
                        return .value
                    }
            }
            .flatMap { _ -> Result<Unit, EcliptixProtocolFailure> in
                var newDhPrivateKey: Data? = nil
                var newDhPublicKey: Data? = nil
                return self.sendingStep.updateKeysAfterDhRatchet(newChainKey: &localSenderCk!, newDhPrivateKey: &newDhPrivateKey, newDhPublicKey: &newDhPublicKey) // maybe here error
            }
            .flatMap { _ -> Result<EcliptixProtocolChainStep, EcliptixProtocolFailure> in
                return EcliptixProtocolChainStep.create(
                    stepType: .receiver,
                    initialChainKey: &localReceiverCk!,
                    initialDhPrivateKey: &persistentPrivKeyBytes,
                    initialDhPublicKey: &self.persistentDhPublicKey
                )
            }
            .map { receivingStepLocal in
                self.rootKeyHandle = tempRootHandle
                tempRootHandle = nil
                
                self.receivingStep = receivingStepLocal
                
                self.peerDhPublicKey = peerDhPublicCopy
                peerDhPublicCopy = nil
                
                return Unit.value
            }
            .mapError { err in
                debugPrint("[ShieldSession] Error finalizing chain and DH keys: \(err.localizedDescription)")
                tempRootHandle?.dispose()
                return err
            }
    }
    
    internal func prepareNextSendMessage() -> Result<(messageKey: EcliptixMessageKey, includeDhKey: Bool), EcliptixProtocolFailure> {
        lock.lock()
        var keyMaterial: Data? = nil

        defer {
            _ = EcliptixProtocolConnection.wipeIfNotNil(&keyMaterial)
            lock.unlock()
        }

        
        return checkDisposed()
            .flatMap { _ in self.ensureNotExpired() }
            .flatMap { _ in self.ensureSendingStepInitialized() }
            .flatMap { sendingStep -> Result<(derivedKey: EcliptixMessageKey, includeDhKey: Bool), EcliptixProtocolFailure> in
                return self.maybePerformSendingDhRatchet(sendingStep: sendingStep)
                    .flatMap { includeDhKey -> Result<(derivedKey: EcliptixMessageKey, includeDhKey: Bool), EcliptixProtocolFailure> in
                        return sendingStep.getCurrentIndex()
                            .flatMap { currentIndex -> Result<(derivedKey: EcliptixMessageKey, includeDhKey: Bool), EcliptixProtocolFailure> in
                                return sendingStep.getOrDeriveKeyFor(targetIndex: currentIndex + 1, messageKeys: &self.messageKeys)
                                    .flatMap { derivedKey -> Result<(derivedKey: EcliptixMessageKey, includeDhKey: Bool), EcliptixProtocolFailure> in
                                        return sendingStep.setCurrentIndex(currentIndex + 1)
                                            .map { _ in
                                                (derivedKey: derivedKey, includeDhKey: includeDhKey)
                                            }
                                    }
                            }
                    }
            }
            .flatMap { resultTuple in
                let originalKey: EcliptixMessageKey = resultTuple.derivedKey
                let includeDhKey = resultTuple.includeDhKey
                
                keyMaterial = Data(count: Constants.aesKeySize)
                var keySpan = Data(count: Constants.aesKeySize)
                _ = originalKey.readKeyMaterial(into: &keySpan)
                
                return EcliptixMessageKey.new(index: originalKey.index, keyMaterial: &keySpan)
                    .map { clonedKey in (clonedKey, includeDhKey) }
            }
            .map { finalResult in
                self.sendingStep.pruneOldKeys(messageKeys: &messageKeys)
                return finalResult
            }
    }
    
    // stopped here
    internal func processReceivedMessage(receivedIndex: UInt32, receivedDhPublicKeyBytes: inout Data?) -> Result<EcliptixMessageKey, EcliptixProtocolFailure> {
        lock.lock()
        
        var receivingStepLocal: EcliptixProtocolChainStep?
        var peerDhPublicCopy: Data? = nil
        var messageKey: EcliptixMessageKey?

        defer {
            _ = Self.wipeIfNotNil(&peerDhPublicCopy)
            lock.unlock()
        }

        debugPrint("[ShieldSession] Processing received message for session \(id), Index: \(receivedIndex)")
        if receivedDhPublicKeyBytes != nil {
            peerDhPublicCopy = Data(receivedDhPublicKeyBytes!)
            debugPrint("[ShieldSession] Received DH Public Key: \(peerDhPublicCopy!.hexEncodedString())")
        }

        return checkDisposed()
            .flatMap { _ in self.ensureNotExpired() }
            .flatMap { _ in self.ensureReceivingStepInitialized() }
            .flatMap { step in
                receivingStepLocal = step
                return maybePerformReceivingDhRatchet(receivingStep: step, receivedDhPublicKeyBytes: &peerDhPublicCopy)
            }
            .flatMap { _ in
                receivingStepLocal!.getOrDeriveKeyFor(targetIndex: receivedIndex, messageKeys: &messageKeys)
            }
            .flatMap { derivedKey in
                messageKey = derivedKey
                debugPrint("[ShieldSession] Derived message key for received index: \(receivedIndex)")
                return receivingStepLocal!.setCurrentIndex(messageKey!.index)
                    .map { _ in messageKey! }
            }
            .map { finalKey in
                receivingStepLocal!.pruneOldKeys(messageKeys: &messageKeys)
                return finalKey
            }
    }

    private func checkIfNotFinalized() -> Result<Unit, EcliptixProtocolFailure> {
        return checkDisposed().flatMap { _ in
            return (rootKeyHandle != nil || receivingStep != nil)
                ? .failure(.generic("Session has not yet been finalized."))
                : .success(Unit.value)
        }
    }

    private static func validateInitialKeys(rootKey: Data, peerDhKey: Data) -> Result<Unit, EcliptixProtocolFailure> {
        if rootKey.count != Constants.x25519KeySize {
            return .failure(.invalidInput("Initial root key must be \(Constants.x25519KeySize) bytes."))
        }

        if peerDhKey.count != Constants.x25519PublicKeySize {
            return .failure(.invalidInput("Initial peer DH public key must be \(Constants.x25519PublicKeySize) bytes."))
        }

        return .success(Unit.value)
    }
    
    private func deriveInitialChainKeys(rootKey: inout Data, senderCkDest: inout Data, receiverCkDest: inout Data) -> Result<Unit, EcliptixProtocolFailure> {
        return Result<Unit, EcliptixProtocolFailure>.Try{
            var sendSpan = Data(repeating: 0, count: Constants.x25519KeySize)
            var recvSpan = Data(repeating: 0, count: Constants.x25519KeySize)

            var saltHkdfSend: Data? = nil
            let hkdfSend = try HkdfSha256(ikm: &rootKey, salt: &saltHkdfSend)
            try hkdfSend.expand(info: Self.initialSenderChainInfo, output: &sendSpan)

            var saltHkdfRecv: Data? = nil
            let hkdfRecv = try HkdfSha256(ikm: &rootKey, salt: &saltHkdfRecv)
            try hkdfRecv.expand(info: Self.initialReceiverChainInfo, output: &recvSpan)
            
            if self.isInitiator {
                senderCkDest.replaceSubrange(0..<sendSpan.count, with: sendSpan)
                receiverCkDest.replaceSubrange(0..<recvSpan.count, with: recvSpan)
            } else {
                senderCkDest.replaceSubrange(0..<recvSpan.count, with: recvSpan)
                receiverCkDest.replaceSubrange(0..<sendSpan.count, with: sendSpan)
            }
        }.mapError { error in
            EcliptixProtocolFailure.deriveKey("Failed to derive initial chain keys.", inner: error)
        }
    }
    
    private func ensureSendingStepInitialized() -> Result<EcliptixProtocolChainStep, EcliptixProtocolFailure> {
        return checkDisposed().flatMap { _ in
            return sendingStep != nil
            ? .success(sendingStep)
            : .failure(EcliptixProtocolFailure.generic("Sending chain step not initialized."))
        }
    }
    
    private func ensureReceivingStepInitialized() -> Result<EcliptixProtocolChainStep, EcliptixProtocolFailure> {
        return checkDisposed().flatMap { _ in
            if receivingStep != nil {
                return .success(receivingStep!)
            } else {
                return .failure(EcliptixProtocolFailure.generic("Receiving chain step not initialized."))
            }
        }
    }
    
    private func maybePerformSendingDhRatchet(sendingStep: EcliptixProtocolChainStep) -> Result<Bool, EcliptixProtocolFailure> {
        return sendingStep.getCurrentIndex().flatMap { currentIndex in
            let shouldRatchet = (Int(currentIndex) + 1) % Self.dhRotationInterval == 0 || self.receivedNewDhKey

            if shouldRatchet {
                return performDhRatchet(isSender: true, receivedDhPublicKeyBytes: nil)
                    .map { _ in
                        receivedNewDhKey = false
                        return true
                    }
            }

            return .success(false)
        }
    }
    
    private func maybePerformReceivingDhRatchet(
        receivingStep: EcliptixProtocolChainStep,
        receivedDhPublicKeyBytes: inout Data?
    ) -> Result<Unit, EcliptixProtocolFailure> {
        if receivedDhPublicKeyBytes == nil {
            return .success(Unit.value)
        }

        do {
            let keysDiffer = peerDhPublicKey == nil || peerDhPublicKey != receivedDhPublicKeyBytes
        
            if self.peerDhPublicKey != nil {
                debugPrint("[ShieldSession] Checking DH key difference. Peer DH Key: \(peerDhPublicKey!.hexEncodedString()), Received: \(receivedDhPublicKeyBytes!.hexEncodedString())")
            }
            
            if !keysDiffer {
                return .success(Unit.value)
            }

            let currentIndexResult = receivingStep.getCurrentIndex()
            if currentIndexResult.isErr {
                return .failure(try currentIndexResult.unwrapErr())
            }
            
            let currentIndex: UInt32 = try currentIndexResult.unwrap()
            let shouldRatchet = isFirstReceivingRatchet || (currentIndex + 1) % UInt32(Self.dhRotationInterval) == 0
            if shouldRatchet {
                return performDhRatchet(isSender: false, receivedDhPublicKeyBytes: receivedDhPublicKeyBytes)
            }
            

            _ = Self.wipeIfNotNil(&peerDhPublicKey)
            peerDhPublicKey = receivedDhPublicKeyBytes
            receivedNewDhKey = true
            debugPrint("[ShieldSession] Deferred DH ratchet: New key received but waiting for interval.")
            return .success(Unit.value)
        } catch {
            return .failure(EcliptixProtocolFailure.generic("Unexpected error during perform receiving DhRatchet.", inner: error))
        }
    }

    
    func performReceivingRatchet(receivedDhKey: Data) -> Result<Unit, EcliptixProtocolFailure> {
        debugPrint("[ShieldSession] Performing receiving ratchet for session \(id)")
        return performDhRatchet(isSender: false, receivedDhPublicKeyBytes: receivedDhKey)
    }
    
    func performDhRatchet(isSender: Bool, receivedDhPublicKeyBytes: Data?) -> Result<Unit, EcliptixProtocolFailure> {
        var dhSecret: Data? = nil
        var newRootKey: Data? = nil
        var newChainKeyForTargetStep: Data? = nil
        var newEphemeralPublicKey: Data? = nil
        var localPrivateKeyBytes: Data? = nil
        var currentRootKey: Data? = nil
        var newDhPrivateKey: Data? = nil
        var hkdfOutput: Data? = nil
        
        var newEphemeralSkHandle: SodiumSecureMemoryHandle? = nil
        

        defer {
            _ = EcliptixProtocolConnection.wipeIfNotNil(&dhSecret)
            _ = EcliptixProtocolConnection.wipeIfNotNil(&newRootKey)
            _ = EcliptixProtocolConnection.wipeIfNotNil(&newChainKeyForTargetStep)
            _ = EcliptixProtocolConnection.wipeIfNotNil(&newEphemeralPublicKey)
            _ = EcliptixProtocolConnection.wipeIfNotNil(&localPrivateKeyBytes)
            _ = EcliptixProtocolConnection.wipeIfNotNil(&currentRootKey)
            _ = EcliptixProtocolConnection.wipeIfNotNil(&newDhPrivateKey)
            
            if hkdfOutput != nil {
                hkdfOutput!.resetBytes(in: 0...hkdfOutput!.count)
                hkdfOutput!.removeAll()
            }
            newEphemeralSkHandle?.dispose()
        }

        do {
            debugPrint("[ShieldSession] Performing DH ratchet for session \(id), IsSender: \(isSender)")

            let initailCheck = checkDisposed().flatMap { _ in
                return rootKeyHandle!.isInvalid == false
                ? .success(Unit.value)
                : .failure(.generic("Root key handle not initialized or invalid."))
            }
            if initailCheck.isErr {
                return initailCheck
            }

            let dhResult: Result<Data, EcliptixProtocolFailure>

            let dhCalculationResult = Result<Unit, EcliptixProtocolFailure>.Try {
                if isSender {
                    if sendingStep == nil || peerDhPublicKey == nil {
                        throw EcliptixProtocolConnectionExceptions.ArgumentNil(message: "Sender ratchet pre-conditions not met.")
                    }
                    let ephResult = try SodiumInterop.generateX25519KeyPair(keyPurpose: "Ephemeral DH Ratchet").unwrap()
                    
                    newEphemeralSkHandle = ephResult.skHandle
                    newEphemeralPublicKey = ephResult.pk
                    localPrivateKeyBytes = try newEphemeralSkHandle!.readBytes(length: Constants.x25519PrivateKeySize).unwrap()
                    dhSecret = try ScalarMult.mult(localPrivateKeyBytes!, peerDhPublicKey!)
                } else {
                    if self.receivingStep == nil || receivedDhPublicKeyBytes!.count != Constants.x25519PublicKeySize {
                        throw EcliptixProtocolConnectionExceptions.ArgumentNil(message: "Receiver ratchet pre-conditions not met.")
                    }
                    localPrivateKeyBytes = try self.currentSendingDhPrivateKeyHandle!.readBytes(length: Constants.x25519PrivateKeySize).unwrap()
                    dhSecret = try ScalarMult.mult(localPrivateKeyBytes!, receivedDhPublicKeyBytes!)
                    
                }
            }.mapError { error in
                EcliptixProtocolFailure.deriveKey("DH calculation failed during ratchet.", inner: error)
            }
             
            if dhCalculationResult.isErr {
                return dhCalculationResult
            }
            
            currentRootKey = try self.rootKeyHandle!.readBytes(length: Constants.x25519KeySize).unwrap()
            hkdfOutput = Data(count: Constants.x25519KeySize * 2)
            let hkdf = try HkdfSha256(ikm: &dhSecret!, salt: &currentRootKey)
            try hkdf.expand(info: Self.dhRatchetInfo, output: &hkdfOutput!)
            
            newRootKey = Data(hkdfOutput!.prefix(Constants.x25519KeySize))
            newChainKeyForTargetStep = Data(hkdfOutput!.dropFirst(Constants.x25519KeySize))
            
            let writeResult = newRootKey!.withUnsafeBytes { bufferPointer in
                self.rootKeyHandle!.write(data: bufferPointer).mapSodiumFailure()
            }
            if writeResult.isErr {
                return writeResult.mapError { f in f }
            }
            
            var updateResult: Result<Unit, EcliptixProtocolFailure>
            if isSender {
                newDhPrivateKey = try newEphemeralSkHandle!.readBytes(length: Constants.x25519PrivateKeySize).unwrap()
                self.currentSendingDhPrivateKeyHandle?.dispose()
                self.currentSendingDhPrivateKeyHandle = newEphemeralSkHandle
                newEphemeralSkHandle = nil
                updateResult = self.sendingStep.updateKeysAfterDhRatchet(newChainKey: &newChainKeyForTargetStep!, newDhPrivateKey: &newDhPrivateKey, newDhPublicKey: &newEphemeralPublicKey)
            } else {
                var newDhPrivateKey: Data? = nil
                var newDhPublicKey: Data? = nil
                updateResult = self.receivingStep!.updateKeysAfterDhRatchet(newChainKey: &newChainKeyForTargetStep!, newDhPrivateKey: &newDhPrivateKey, newDhPublicKey: &newDhPublicKey)
                if updateResult.isOk {
                    _ = Self.wipeIfNotNil(&self.peerDhPublicKey)
                    self.peerDhPublicKey = receivedDhPublicKeyBytes
                }
            }
            
            if updateResult.isErr {
                return updateResult
            }
            
            self.receivedNewDhKey = false
            clearMessageKeyCache()
            return .success(.value)
        } catch {
            return .failure(EcliptixProtocolFailure.generic("Unexpected error during perform DhRatchet.", inner: error))
        }
    }


    internal func generateNextNonce() -> Result<Data, EcliptixProtocolFailure> {
        return checkDisposed().map { _ in
            var nonceBuffer = Data(count: EcliptixProtocolConnection.aesGcmNonceSize)
            
            // Fill first 8 bytes with random data
            var randomBytes = [UInt8](repeating: 0, count: 8)
            let result = SecRandomCopyBytes(kSecRandomDefault, 8, &randomBytes)
            if result == errSecSuccess {
                nonceBuffer.replaceSubrange(0..<8, with: randomBytes)
            } else {
                // You may want to handle random generation errors differently
                fatalError("Failed to generate random bytes for nonce")
            }
            
            let currentNonce = nonceCounter.wrappingIncrementThenLoad(ordering: .relaxed) - 1
            
            // Write the UInt32 counter in little-endian format to nonceBuffer[8...]
            var counterBytes = withUnsafeBytes(of: currentNonce.littleEndian) { Data($0) }
            nonceBuffer.replaceSubrange(8..<12, with: counterBytes)
            
            // Debug logging (Swift equivalent of Debug.WriteLine)
            debugPrint("[ShieldSession] Generated nonce: \(nonceBuffer.hexEncodedString()) for counter: \(currentNonce)")
            
            randomBytes.resetBytes(in: 0..<randomBytes.count)
            counterBytes.resetBytes(in: 0..<counterBytes.count)
            
            return nonceBuffer
        }
    }
    
    func getCurrentPeerDhPublicKey() -> Result<Data?, EcliptixProtocolFailure> {
        return checkDisposed().map { _ in
            return peerDhPublicKey
        }
    }
    
    func getCurrentSenderDhPublicKey() -> Result<Data?, EcliptixProtocolFailure> {
        return checkDisposed()
            .flatMap { _ in ensureSendingStepInitialized() }
            .flatMap { step in step.readDhPublicKey() }
    }

    private func ensureNotExpired() -> Result<Unit, EcliptixProtocolFailure> {
        return checkDisposed().flatMap { _ in
            let expired = Date().timeIntervalSince(createdAt) > EcliptixProtocolConnection.sessionTimeout
            return expired
                ? .failure(.generic("Session \(id) has expired."))
                : .success(.value)
        }
    }
    
    private func clearMessageKeyCache() {
        debugPrint("[ShieldSession] Clearing message key cache for session \(id)")
        for (key, value) in messageKeys {
            value.dispose()
        }
        messageKeys.removeAll()
    }
    
    private func checkDisposed() -> Result<Unit, EcliptixProtocolFailure> {
        if disposed {
            return .failure(.objectDisposed(String(describing: EcliptixProtocolConnection.self)))
        } else {
            return .success(.value)
        }
    }

    
    private static func wipeIfNotNil(_ data: inout Data?) -> Result<Unit, EcliptixProtocolFailure> {
        var mutableData: Data? = data
        if mutableData == nil {
            return .success(Unit())
        }
        return SodiumInterop.secureWipe(&mutableData).mapSodiumFailure()
    }


 
    private func dispose(disposing: Bool) {
        if disposed { return }
        
        debugPrint("[ShieldSession] Disposing session \(id)")
        disposed = true
        
        if disposing {
            secureCleaningLogic()
        }
    }
    
    private func secureCleaningLogic() {
        rootKeyHandle?.dispose()
        sendingStep?.dispose()
        receivingStep?.dispose()
        clearMessageKeyCache()
        persistentDhPrivateKeyHandle?.dispose()
        initialSendingDhPrivateKeyHandle?.dispose()
        currentSendingDhPrivateKeyHandle?.dispose()
        _ = EcliptixProtocolConnection.wipeIfNotNil(&peerDhPublicKey)
        _ = EcliptixProtocolConnection.wipeIfNotNil(&persistentDhPublicKey)
        peerDhPublicKey = nil
        persistentDhPublicKey = nil
        initialSendingDhPrivateKeyHandle = nil
        persistentDhPrivateKeyHandle = nil
        currentSendingDhPrivateKeyHandle = nil
        debugPrint("[ShieldSession] Session \(id) disposed.")
    }
}

extension Data {
    func hexEncodedString() -> String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
}

@discardableResult
func atomicIncrement(_ pointer: UnsafeMutablePointer<UInt32>) -> UInt32 {
    let incrementedValue = OSAtomicIncrement32(UnsafeMutablePointer<Int32>(OpaquePointer(pointer)))
    return UInt32(bitPattern: incrementedValue)
}
