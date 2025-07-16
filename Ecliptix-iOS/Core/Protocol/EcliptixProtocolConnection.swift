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
import SwiftProtobuf

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
    private let sendingStep: EcliptixProtocolChainStep
    private var currentSendingDhPrivateKeyHandle: SodiumSecureMemoryHandle?
    private var initialSendingDhPrivateKeyHandle: SodiumSecureMemoryHandle?
    private let nonceCounter: ManagedAtomic<UInt32>
    private var peerBundle: PublicKeyBundle?
    private var peerDhPublicKey: Data?
    private var persistentDhPrivateKeyHandle: SodiumSecureMemoryHandle?
    private var persistentDhPublicKey: Data?
    private var receivedNewDhKey: Bool
    private var receivingStep: EcliptixProtocolChainStep?
    private var rootKeyHandle: SodiumSecureMemoryHandle?
    
    
    public var disposed = false
    
    private init(
        id: UInt32,
        isInitiator: Bool,
        initialSendingDh: SodiumSecureMemoryHandle,
        sendingStep: EcliptixProtocolChainStep,
        persistentDh: SodiumSecureMemoryHandle,
        persistentDhPublic: Data) {
        
        self.id = id
        self.isInitiator = isInitiator
        self.initialSendingDhPrivateKeyHandle = initialSendingDh
        self.currentSendingDhPrivateKeyHandle = initialSendingDh
        self.sendingStep = sendingStep
        self.persistentDhPrivateKeyHandle = persistentDh
        self.persistentDhPublicKey = persistentDhPublic
        self.nonceCounter = ManagedAtomic<UInt32>(0)
        
        self.peerBundle = nil
        self.receivingStep = nil
        self.rootKeyHandle = nil
        self.createdAt = Date()
        self.peerDhPublicKey = nil
        self.receivedNewDhKey = false
        self.isFirstReceivingRatchet = true
    }
    
    private init(
        id: UInt32,
        proto: Ecliptix_Proto_KeyMaterials_RatchetState,
        sendingStep: EcliptixProtocolChainStep,
        receivingStep: EcliptixProtocolChainStep?,
        rootKeyHandle: SodiumSecureMemoryHandle) {
            
        self.id = id
        self.isInitiator = proto.isInitiator
        self.createdAt = proto.createdAt.toDate()
        self.nonceCounter = ManagedAtomic(UInt32(clamping: proto.nonceCounter))
            
        guard let peerBundle = try? PublicKeyBundle.fromProtobufExchange(proto.peerBundle).unwrap() else {
            fatalError("Failed to parse PublicKeyBundle")
        }
        self.peerBundle = peerBundle

        self.peerDhPublicKey = proto.peerDhPublicKey.isEmpty ? nil : Data(proto.peerDhPublicKey)
        self.isFirstReceivingRatchet = proto.isFirstReceivingRatchet
        self.rootKeyHandle = rootKeyHandle
        self.sendingStep = sendingStep
        self.receivingStep = receivingStep
        self.currentSendingDhPrivateKeyHandle = sendingStep.getDhPrivateKeyHandle()
        self.initialSendingDhPrivateKeyHandle = nil
        self.persistentDhPrivateKeyHandle = nil
        self.persistentDhPublicKey = nil
        self.receivedNewDhKey = false
        self.disposed = false
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
            let overallResult = SodiumInterop.generateX25519KeyPair(keyPurpose: "Initial Sending DH")
                .flatMap { initialSendKeys in
                    initialSendingDhPrivateKeyHandle = initialSendKeys.skHandle
                    initialSendingDhPublicKey = initialSendKeys.pk
                                    
                    return initialSendingDhPrivateKeyHandle!.readBytes(length: Constants.x25519PrivateKeySize)
                        .mapSodiumFailure()
                        .map { bytes in
                            initialSendingDhPrivateKeyBytes = bytes
                            return Unit.value
                        }
                }
                .flatMap { _ in SodiumInterop.generateX25519KeyPair(keyPurpose: "Persistent DH") }
                .flatMap { persistentKeys in
                    persistentDhPrivateKeyHandle = persistentKeys.skHandle
                    persistentDhPublicKey = persistentKeys.pk
                    
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
                    
                    let connection = EcliptixProtocolConnection(
                        id: connectId,
                        isInitiator: isInitiator,
                        initialSendingDh: initialSendingDhPrivateKeyHandle!,
                        sendingStep: sendingStep!,
                        persistentDh: persistentDhPrivateKeyHandle!,
                        persistentDhPublic: persistentDhPublicKey!
                    )

                    initialSendingDhPrivateKeyHandle = nil
                    persistentDhPrivateKeyHandle = nil
                    sendingStep = nil

                    return .success(connection)
                }

            if overallResult.isErr {
                initialSendingDhPrivateKeyHandle?.dispose()
                sendingStep?.dispose()
                persistentDhPrivateKeyHandle?.dispose()
                _ = wipeIfNotNil(&initialSendingDhPrivateKeyBytes)
            }
            
            return overallResult

        } catch {
            initialSendingDhPrivateKeyHandle?.dispose()
            sendingStep?.dispose()
            persistentDhPrivateKeyHandle?.dispose()
            _ = wipeIfNotNil(&initialSendingDhPrivateKeyBytes)
            return .failure(EcliptixProtocolFailure.generic("Unexpected error creating session \(connectId).", inner: error))
        }
    }
    
    public func toProtoState() -> Result<Ecliptix_Proto_KeyMaterials_RatchetState, EcliptixProtocolFailure> {
        lock.lock()
        
        defer {
            lock.unlock()
        }
        
        guard !self.disposed else {
            return .failure(.objectDisposed(String(describing: EcliptixProtocolConnection.self)))
        }
        
        do {
            let sendingStepResult = self.sendingStep.toProtoState()
            guard sendingStepResult.isOk else {
                return .failure(try sendingStepResult.unwrapErr())
            }
            
            let rootKeyResult = self.rootKeyHandle!.readBytes(length: Constants.x25519KeySize).mapSodiumFailure()
            guard rootKeyResult.isOk else {
                return .failure(try rootKeyResult.unwrapErr())
            }
            
            var proto = Ecliptix_Proto_KeyMaterials_RatchetState()
            proto.isInitiator = self.isInitiator
            proto.createdAt = .fromDate(date: self.createdAt)
            proto.nonceCounter = UInt64(self.nonceCounter.load(ordering: .relaxed))
            proto.peerBundle = self.peerBundle!.toProtobufExchange()
            proto.peerDhPublicKey = self.peerDhPublicKey ?? Data()
            proto.isFirstReceivingRatchet = self.isFirstReceivingRatchet
            proto.rootKey = try rootKeyResult.unwrap()
            proto.sendingStep = try sendingStepResult.unwrap()
            
            if self.receivingStep != nil {
                let receivingStepResult = self.receivingStep!.toProtoState()
                guard receivingStepResult.isOk else {
                    return .failure(try receivingStepResult.unwrapErr())
                }
                proto.receivingStep = try receivingStepResult.unwrap()
            }
            
            return .success(proto)
        } catch {
            return .failure(.generic("Failed to export connection to proto state.", inner: error))
        }
    }
    
    public static func fromProtoState(connectId: UInt32, proto: Ecliptix_Proto_KeyMaterials_RatchetState) -> Result<EcliptixProtocolConnection, EcliptixProtocolFailure> {
        var sendingStep: EcliptixProtocolChainStep? = nil
        var receivingStep: EcliptixProtocolChainStep? = nil
        var rootKeyHandle: SodiumSecureMemoryHandle? = nil
        
        defer {
            sendingStep = nil
            receivingStep = nil
            rootKeyHandle = nil
            
            sendingStep?.dispose()
            receivingStep?.dispose()
            rootKeyHandle?.dispose()
        }
        
        do {
            let sendingStepResult = EcliptixProtocolChainStep.fromProtoState(stepType: .sender, proto: proto.sendingStep)
            guard sendingStepResult.isOk else {
                return .failure(try sendingStepResult.unwrapErr())
            }
            sendingStep = try sendingStepResult.unwrap()
            
            let receivingStepResult = EcliptixProtocolChainStep.fromProtoState(stepType: .receiver, proto: proto.receivingStep)
            guard receivingStepResult.isOk else {
                return .failure(try receivingStepResult.unwrapErr())
            }
            receivingStep = try receivingStepResult.unwrap()
            
            let rootKeyResult = SodiumSecureMemoryHandle.allocate(length: proto.rootKey.count).mapSodiumFailure()
            guard rootKeyResult.isOk else {
                return .failure(try rootKeyResult.unwrapErr())
            }
            rootKeyHandle = try rootKeyResult.unwrap()
            
            _ = try proto.rootKey.withUnsafeBytes { bufferPointer in
                rootKeyHandle!.write(data: bufferPointer).mapSodiumFailure()
            }.unwrap()
            
            let connection = EcliptixProtocolConnection(id: connectId, proto: proto, sendingStep: sendingStep!, receivingStep: receivingStep, rootKeyHandle: rootKeyHandle!)
            
            return .success(connection)
        } catch {
            return .failure(.generic("Failed to rehydrate connection from proto state.", inner: error))
        }
    }
    
    public func syncWithRemoteState(remoteSendingChainLength: UInt32, remoteReceivingChainLength: UInt32) -> Result<Unit, EcliptixProtocolFailure> {
        lock.lock()
        
        defer {
            lock.unlock()
        }
        
        return checkDisposed()
            .flatMap { _ in self.ensureReceivingStepInitialized() }
            .flatMap { receivingStep in receivingStep.skipKeysUntil(targetIndex: remoteSendingChainLength) }
            .flatMap { _ in self.ensureSendingStepInitialized() }
            .flatMap { sendingStep in sendingStep.skipKeysUntil(targetIndex: remoteReceivingChainLength) }
    }
    
    public func getPeerBundle() -> Result<PublicKeyBundle, EcliptixProtocolFailure> {
        lock.lock()
        defer { lock.unlock() }
        
        return checkDisposed().flatMap { _ in
            return self.peerBundle != nil
            ? .success(self.peerBundle!)
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
        
        return checkDisposed().map { u in u }
    }
    
    internal func setPeerBundle(_ peerBundleToSet: PublicKeyBundle?) -> Result<Unit, EcliptixProtocolFailure> {
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
                localSenderCk!.resetBytes(in: 0..<localSenderCk!.count)
                localSenderCk!.removeAll()
            }
            if localReceiverCk != nil {
                localReceiverCk!.resetBytes(in: 0..<localReceiverCk!.count)
                localReceiverCk!.removeAll()
            }
            
            _ = Self.wipeIfNotNil(&peerDhPublicCopy)
            _ = Self.wipeIfNotNil(&persistentPrivKeyBytes)
            lock.unlock()
        }

        return checkDisposed()
            .flatMap { _ in checkIfNotFinalized() }
            .flatMap { _ in Self.validateInitialKeys(rootKey: initialRootKey, peerDhKey: initialPeerDhPublicKey) }
            .flatMap { _ in
                peerDhPublicCopy = initialPeerDhPublicKey

                return SodiumSecureMemoryHandle.allocate(length: Constants.x25519KeySize)
                    .mapSodiumFailure()
                    .flatMap { handle -> Result<Unit, EcliptixProtocolFailure> in
                        tempRootHandle = handle
                        
                        return initialRootKey.withUnsafeBytes { bufferPointer in
                            handle.write(data: bufferPointer).mapSodiumFailure()
                        }
                    }
            }
            .flatMap { _ in
                localSenderCk = Data(count: Constants.x25519KeySize)
                localReceiverCk = Data(count: Constants.x25519KeySize)
                return deriveInitialChainKeys(rootKey: &initialRootKey, senderCkDest: &localSenderCk!, receiverCkDest: &localReceiverCk!)
            }
            .flatMap { _ in
                return self.persistentDhPrivateKeyHandle!.readBytes(length: Constants.x25519PrivateKeySize)
                    .mapSodiumFailure()
                    .map { bytes -> Unit in
                        persistentPrivKeyBytes = bytes
                        return .value
                    }
            }
            .flatMap { _ in
                var newDhPrivateKey: Data? = nil
                var newDhPublicKey: Data? = nil
                return self.sendingStep.updateKeysAfterDhRatchet(newChainKey: &localSenderCk!, newDhPrivateKey: &newDhPrivateKey, newDhPublicKey: &newDhPublicKey)
            }
            .flatMap { _  in
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
                                return sendingStep.getOrDeriveKeyFor(targetIndex: currentIndex + 1)
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
                let originalKey = resultTuple.derivedKey
                let includeDhKey = resultTuple.includeDhKey
                
                keyMaterial = Data(count: Constants.aesKeySize)
                _ = originalKey.readKeyMaterial(into: &keyMaterial!)
                
                return EcliptixMessageKey.new(index: originalKey.index, keyMaterial: &keyMaterial!)
                    .map { clonedKey in (clonedKey, includeDhKey) }
            }
            .map { finalResult in
                self.sendingStep.pruneOldKeys()
                return finalResult
            }
    }
    
    // stopped here
    internal func processReceivedMessage(receivedIndex: UInt32, receivedDhPublicKeyBytes: inout Data?) -> Result<EcliptixMessageKey, EcliptixProtocolFailure> {
        lock.lock()

        defer {
            lock.unlock()
        }
        
        return checkDisposed()
            .flatMap { _ in ensureNotExpired() }
            .flatMap { _ in ensureReceivingStepInitialized() }
            .flatMap { receivingStep in maybePerformReceivingDhRatchet(receivingStep: receivingStep, receivedDhPublicKeyBytes: &receivedDhPublicKeyBytes)
                    .flatMap { _ in receivingStep.getOrDeriveKeyFor(targetIndex: receivedIndex) }
                    .flatMap { derivedKey in receivingStep.setCurrentIndex(derivedKey.index).map { _ in derivedKey } }
            }
            .map { finalKey in
                self.receivingStep!.pruneOldKeys()
                return finalKey
            }
    }

    private func checkIfNotFinalized() -> Result<Unit, EcliptixProtocolFailure> {
        return checkDisposed().flatMap { _ in
            return (self.rootKeyHandle != nil || self.receivingStep != nil)
                ? .failure(.generic("Session has not yet been finalized."))
                : .success(.value)
        }
    }

    private static func validateInitialKeys(rootKey: Data, peerDhKey: Data) -> Result<Unit, EcliptixProtocolFailure> {
        guard rootKey.count == Constants.x25519KeySize else {
            return .failure(.invalidInput("Initial root key must be \(Constants.x25519KeySize) bytes."))
        }

        guard peerDhKey.count == Constants.x25519PublicKeySize else {
            return .failure(.invalidInput("Initial peer DH public key must be \(Constants.x25519PublicKeySize) bytes."))
        }

        return .success(.value)
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
                senderCkDest = sendSpan
                receiverCkDest = recvSpan
            } else {
                senderCkDest = recvSpan
                receiverCkDest = sendSpan
            }
            
            return .value
        } errorMapper: { error in
            EcliptixProtocolFailure.deriveKey("Failed to derive initial chain keys.", inner: error)
        }
    }
    
    private func ensureSendingStepInitialized() -> Result<EcliptixProtocolChainStep, EcliptixProtocolFailure> {
        return checkDisposed().flatMap { _ in
            return self.sendingStep != nil
            ? .success(self.sendingStep)
            : .failure(EcliptixProtocolFailure.generic("Sending chain step not initialized."))
        }
    }
    
    private func ensureReceivingStepInitialized() -> Result<EcliptixProtocolChainStep, EcliptixProtocolFailure> {
        return checkDisposed().flatMap { _ in
            if self.receivingStep != nil {
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
            return .success(.value)
        }
        
        let keysDiffer = peerDhPublicKey == nil || peerDhPublicKey != receivedDhPublicKeyBytes
        
        if !keysDiffer {
            return .success(.value)
        }
        
        return receivingStep.getCurrentIndex().flatMap { currentIndex in
            let shouldRatchet = isFirstReceivingRatchet || (currentIndex + 1) % UInt32(Self.dhRotationInterval) == 0
            if shouldRatchet {
                self.isFirstReceivingRatchet = false
                return performDhRatchet(isSender: false, receivedDhPublicKeyBytes: receivedDhPublicKeyBytes)
            } else {
                _ = Self.wipeIfNotNil(&peerDhPublicKey)
                peerDhPublicKey = receivedDhPublicKeyBytes
                receivedNewDhKey = true
                return .success(.value)
            }
        }
    }

    
    func performReceivingRatchet(receivedDhKey: Data) -> Result<Unit, EcliptixProtocolFailure> {
        lock.lock()
        
        defer {
            lock.unlock()
        }
        
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
                hkdfOutput!.resetBytes(in: 0..<hkdfOutput!.count)
                hkdfOutput!.removeAll()
            }
            newEphemeralSkHandle?.dispose()
        }

        do {
            let initailCheck = checkDisposed().flatMap { _ in
                return self.rootKeyHandle!.isInvalid == false
                ? .success(Unit.value)
                : .failure(.generic("Root key handle not initialized or invalid."))
            }
            if initailCheck.isErr {
                return initailCheck
            }

            let dhCalculationResult = Result<Unit, EcliptixProtocolFailure>.Try {
                if isSender {
                    if self.sendingStep == nil || self.peerDhPublicKey == nil {
                        throw EcliptixProtocolConnectionExceptions.ArgumentNil(message: "Sender ratchet pre-conditions not met.")
                    }
                    let ephResult = try SodiumInterop.generateX25519KeyPair(keyPurpose: "Ephemeral DH Ratchet").unwrap()
                    
                    newEphemeralSkHandle = ephResult.skHandle
                    newEphemeralPublicKey = ephResult.pk
                    localPrivateKeyBytes = try newEphemeralSkHandle!.readBytes(length: Constants.x25519PrivateKeySize).unwrap()
                    dhSecret = try ScalarMult.mult(localPrivateKeyBytes!, self.peerDhPublicKey!)
                } else {
                    if self.receivingStep == nil || receivedDhPublicKeyBytes!.count != Constants.x25519PublicKeySize {
                        throw EcliptixProtocolConnectionExceptions.ArgumentNil(message: "Receiver ratchet pre-conditions not met.")
                    }
                    localPrivateKeyBytes = try self.currentSendingDhPrivateKeyHandle!.readBytes(length: Constants.x25519PrivateKeySize).unwrap()
                    dhSecret = try ScalarMult.mult(localPrivateKeyBytes!, receivedDhPublicKeyBytes!)
                    
                }
                return .value
            } errorMapper: { error in
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
            
            let updateResult: Result<Unit, EcliptixProtocolFailure>
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
            return .success(.value)
        } catch {
            return .failure(EcliptixProtocolFailure.generic("Unexpected error during perform DhRatchet.", inner: error))
        }
    }


    internal func generateNextNonce() -> Result<Data, EcliptixProtocolFailure> {
        return checkDisposed().map { _ in
            var nonceBuffer = Data(count: EcliptixProtocolConnection.aesGcmNonceSize)
            
            var randomBytes = [UInt8](repeating: 0, count: 8)
            let result = SecRandomCopyBytes(kSecRandomDefault, 8, &randomBytes)
            if result == errSecSuccess {
                nonceBuffer.replaceSubrange(0..<8, with: randomBytes)
            } else {
                fatalError("Failed to generate random bytes for nonce")
            }
            
            let currentNonce = nonceCounter.wrappingIncrementThenLoad(ordering: .relaxed) - 1
            
            var counterBytes = withUnsafeBytes(of: currentNonce.littleEndian) { Data($0) }
            nonceBuffer.replaceSubrange(8..<12, with: counterBytes)
            
            randomBytes.resetBytes(in: 0..<randomBytes.count)
            counterBytes.resetBytes(in: 0..<counterBytes.count)
            
            return nonceBuffer
        }
    }
    
    func getCurrentPeerDhPublicKey() -> Result<Data?, EcliptixProtocolFailure> {
        lock.lock()
        
        defer {
            lock.unlock()
        }
        
        return checkDisposed().map { _ in self.peerDhPublicKey != nil ? self.peerDhPublicKey! : nil }
    }
    
    func getCurrentSenderDhPublicKey() -> Result<Data?, EcliptixProtocolFailure> {
        lock.lock()
        
        defer {
            lock.unlock()
        }
        
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
        
        disposed = true
        
        if disposing {
            secureCleanupLogic()
        }
    }
    
    private func secureCleanupLogic() {
        rootKeyHandle?.dispose()
        sendingStep.dispose()
        receivingStep?.dispose()
        persistentDhPrivateKeyHandle?.dispose()
        if currentSendingDhPrivateKeyHandle != initialSendingDhPrivateKeyHandle {
            currentSendingDhPrivateKeyHandle?.dispose()
        }
        initialSendingDhPrivateKeyHandle?.dispose()
        _ = EcliptixProtocolConnection.wipeIfNotNil(&peerDhPublicKey)
        _ = EcliptixProtocolConnection.wipeIfNotNil(&persistentDhPublicKey)
    }
}

@discardableResult
func atomicIncrement(_ pointer: UnsafeMutablePointer<UInt32>) -> UInt32 {
    let incrementedValue = OSAtomicIncrement32(UnsafeMutablePointer<Int32>(OpaquePointer(pointer)))
    return UInt32(bitPattern: incrementedValue)
}
