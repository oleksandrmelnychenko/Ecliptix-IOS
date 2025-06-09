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

enum ConnectSessionExceptions: Error {
    case ArgumentNil(message: String)
}

final class ConnectSession {
    
    public static let dhRotationInterval = 10
    public static let sessionTimeout: TimeInterval = 24 * 60 * 60 // 24 hours
    public static let initialSenderChainInfo = "ShieldInitSend".data(using: .utf8)!
    public static let initialReceiverChainInfo = "ShieldInitRecv".data(using: .utf8)!
    public static let dhRatchetInfo = "ShieldDhRatchet".data(using: .utf8)!
    public static let aesGcmNonceSize = 12
    
    public let id: UInt32
    public var peerBundle: LocalPublicKeyBundle?
    public var sendingStep: ShieldChainStep?
    public var receivingStep: ShieldChainStep?
    public var rootKeyHandle: SodiumSecureMemoryHandle?
    public var messageKeys: OrderedDictionary<UInt32, ShieldMessageKey>
    public let nonceCounter = ManagedAtomic<UInt32>(0)
    public let createdAt: Date
    public var peerDhPublicKey: Data?
    public let isInitiator: Bool
    public var receivedNewDhKey: Bool = false
    public var persistentDhPrivateKeyHandle: SodiumSecureMemoryHandle?
    public var persistentDhPublicKey: Data?
    public var initialSendingDhPrivateKeyHandle: SodiumSecureMemoryHandle?
    public var currentSendingDhPrivateKeyHandle: SodiumSecureMemoryHandle?
    public let isFirstReceivingRatchet: Bool
    
//    public var state: Ecliptix_Proto_PubKeyExchangeState
    
    public var disposed = false
    
    init(id: UInt32,
         isInitiator: Bool,
         initialSendingDhPrivateHandle: SodiumSecureMemoryHandle,
         sendingStep: ShieldChainStep,
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
    
    static func create(connectId: UInt32, localBundle: LocalPublicKeyBundle, isInitiator: Bool) -> Result<ConnectSession, EcliptixProtocolFailure> {
        var initialSendingDhPrivateKeyHandle: SodiumSecureMemoryHandle? = nil
        var initialSendingDhPublicKey: Data? = nil
        var initialSendingDhPrivateKeyBytes: Data? = nil
        var sendingStep: ShieldChainStep? = nil
        var persistentDhPrivateKeyHandle: SodiumSecureMemoryHandle? = nil
        var persistentDhPublicKey: Data? = nil

        do {
            debugPrint("[ShieldSession] Creating session \(connectId), Initiator: \(isInitiator)")

            let overallResult = generateX25519KeyPair(keyPurpose: "Initial Sending DH")
                .flatMap { initialSendKeys -> Result<Unit, EcliptixProtocolFailure> in
                    initialSendingDhPrivateKeyHandle = initialSendKeys.0
                    initialSendingDhPublicKey = initialSendKeys.1
                    
                    debugPrint("[ShieldSession] Generated Initial Sending DH Public Key: \(initialSendingDhPublicKey!.hexEncodedString())")
                
                    return initialSendingDhPrivateKeyHandle!.readBytes(length: Constants.x25519PrivateKeySize)
                        .map { bytes in
                            initialSendingDhPrivateKeyBytes = Data(bytes)
                            debugPrint("[ShieldSession] Initial Sending DH Private Key: \(initialSendingDhPrivateKeyBytes!.hexEncodedString())")
                            return Unit.value
                        }.mapSodiumFailure()
                }
                .flatMap { _ in
                    generateX25519KeyPair(keyPurpose: "Persistent DH")
                }
                .flatMap { persistentKeys -> Result<ShieldChainStep, EcliptixProtocolFailure> in
                    persistentDhPrivateKeyHandle = persistentKeys.skHandle
                    persistentDhPublicKey = persistentKeys.pk
                    
                    debugPrint("[ShieldSession] Generated Persistent DH Public Key: \(persistentDhPublicKey!.hexEncodedString())")

                    var tempChainKey = Data(count: Constants.x25519KeySize)
                    let stepResult = ShieldChainStep.create(
                        stepType: .sender,
                        initialChainKey: &tempChainKey,
                        initialDhPrivateKey: &initialSendingDhPrivateKeyBytes,
                        initialDhPublicKey: &initialSendingDhPublicKey
                    )
                    _ = SodiumInterop.secureWipe(&tempChainKey)
                    _ = Self.wipeIfNotNil(&initialSendingDhPrivateKeyBytes)
                    initialSendingDhPrivateKeyBytes = nil
            
                    return stepResult
                }
                .flatMap { createdSendingStep in
                    sendingStep = createdSendingStep
                    debugPrint("[ShieldSession] Sending step created for session \(connectId)")

                    let session = ConnectSession(
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

    
    
    private static func generateX25519KeyPair(keyPurpose: String) -> Result<(skHandle: SodiumSecureMemoryHandle, pk: Data), EcliptixProtocolFailure>
        {
        var skHandle: SodiumSecureMemoryHandle? = nil;
        var skBytes: Data?  = nil;
        var tempPrivCopy: Data?  = nil;
        
        do
        {
            debugPrint("[ShieldSession] Generating X25519 key pair for \(keyPurpose)")
            
            let allocResult = SodiumSecureMemoryHandle.allocate(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
            if allocResult.isErr {
                return .failure(try allocResult.unwrapErr());
            }
            
            skHandle = try allocResult.unwrap();
            
            guard let randomBytes = Sodium().randomBytes.buf(length: Constants.x25519PrivateKeySize) else {
                skHandle?.dispose()
                return .failure(.generic("Failed to generate random bytes for \(keyPurpose)"))
            }
            skBytes = Data(randomBytes)
            
            let writeResult = skBytes!.withUnsafeBytes { bufferPointer in
                skHandle!.write(data: bufferPointer).mapSodiumFailure()
            }
            if writeResult.isErr {
                skHandle?.dispose()
                return .failure(try writeResult.unwrapErr())
            }
            
            _ = SodiumInterop.secureWipe(&skBytes)
            skBytes = nil
            
            tempPrivCopy = Data(count: Constants.x25519PrivateKeySize)
            let readResult = tempPrivCopy!.withUnsafeMutableBytes { destPtr in
                skHandle!.read(into: destPtr).mapSodiumFailure()
            }
            if readResult.isErr {
                skHandle?.dispose()
                _ = SodiumInterop.secureWipe(&tempPrivCopy)
                return .failure(try readResult.unwrapErr())
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
            
            debugPrint("[ShieldSession] Generated \(keyPurpose) Public Key: \(pkBytes.hexEncodedString())")
            return .success((skHandle!, pkBytes))
        }
        catch
        {
            debugPrint("[ShieldSession] Error generating \(keyPurpose) key pair: \(error.localizedDescription)")
            skHandle?.dispose()

            if skBytes != nil {
                _ = SodiumInterop.secureWipe(&skBytes)
            }
            if tempPrivCopy != nil {
                _ = SodiumInterop.secureWipe(&tempPrivCopy)
            }

            return .failure(.generic("Unexpected error generating \(keyPurpose) key pair.", inner: error))
        }
    }
    
    public func getPeerBundle() -> Result<LocalPublicKeyBundle, EcliptixProtocolFailure> {
        return checkDisposed().flatMap { _ in
            return peerBundle != nil ? .success(peerBundle!) : .failure(.generic("Peer bundle has not been set."))
        }
    }
    
    public func getIsInitiator() -> Result<Bool, EcliptixProtocolFailure> {
        return checkDisposed().map { _ in
            return isInitiator
        }
    }
    
    internal func setConnectionState(_ newState: Ecliptix_Proto_PubKeyExchangeState) -> Result<Unit, EcliptixProtocolFailure> {
        return checkDisposed().map { u in
            debugPrint("[ShieldSession] Setting state for session \(id) to \(newState)")
            return u
        }
    }
    
    internal func setPeerBundle(_ peerBundleToSet: LocalPublicKeyBundle?) throws {
        if peerBundleToSet == nil {
            throw ConnectSessionExceptions.ArgumentNil(message: String(describing: peerBundle.self))
        }
        
        debugPrint("[ShieldSession] Setting peer bundle for session \(id)")
        peerBundle = peerBundleToSet
    }
    
    internal func finalizeChainAndDhKeys(initialRootKey: inout Data, initialPeerDhPublicKey: inout Data) -> Result<Unit, EcliptixProtocolFailure> {
        var tempRootHandle: SodiumSecureMemoryHandle? = nil
        var tempReceivingStep: ShieldChainStep? = nil
        
        var initialRootKeyCopy: Data? = nil
        var localSenderCk: Data? = nil
        var localReceiverCk: Data? = nil
        var peerDhPublicCopy: Data? = nil
        var persistentPrivKeyBytes: Data? = nil

        defer {
            _ = Self.wipeIfNotNil(&initialRootKeyCopy)
            _ = Self.wipeIfNotNil(&localSenderCk)
            _ = Self.wipeIfNotNil(&localReceiverCk)
            _ = Self.wipeIfNotNil(&peerDhPublicCopy)
            _ = Self.wipeIfNotNil(&persistentPrivKeyBytes)
            tempRootHandle?.dispose()
            tempReceivingStep?.dispose()
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
                initialRootKeyCopy = initialRootKey
                peerDhPublicCopy = initialPeerDhPublicKey

                debugPrint("[ShieldSession] Initial Root Key: \(initialRootKeyCopy!.hexEncodedString())")
                debugPrint("[ShieldSession] Initial Peer DH Public Key: \(peerDhPublicCopy!.hexEncodedString())")

                let result = SodiumSecureMemoryHandle.allocate(length: Constants.x25519KeySize)
                    .mapSodiumFailure()
                    .flatMap { handle -> Result<Unit, EcliptixProtocolFailure> in
                        tempRootHandle = handle
                        
                        return initialRootKeyCopy!.withUnsafeBytes { bufferPointer in
                            handle.write(data: bufferPointer).mapSodiumFailure()
                        }
                    }
                
                return result
            }
            .flatMap { _ -> Result<(senderCk: Data, receiverCk: Data), EcliptixProtocolFailure> in
                return deriveInitialChainKeys(rootKey: &initialRootKeyCopy!)
            }
            .flatMap { derivedKeys -> Result<Unit, EcliptixProtocolFailure> in
                localSenderCk = derivedKeys.senderCk
                localReceiverCk = derivedKeys.receiverCk

                debugPrint("[ShieldSession] Local Sender Chain Key: \(localSenderCk!.hexEncodedString())")
                debugPrint("[ShieldSession] Local Receiver Chain Key: \(localReceiverCk!.hexEncodedString())")

                return persistentDhPrivateKeyHandle!.readBytes(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
                    .map { bytes -> Unit in
                        persistentPrivKeyBytes = bytes
                        debugPrint("[ShieldSession] Persistent DH Private Key: \(persistentPrivKeyBytes!.hexEncodedString())")
                        return Unit.value
                    }
            }
            .flatMap { _ -> Result<Unit, EcliptixProtocolFailure> in
                var newDhPrivateKey: Data? = nil
                var newDhPublicKey: Data? = nil
                return sendingStep!.updateKeysAfterDhRatchet(newChainKey: &localSenderCk!, newDhPrivateKey: &newDhPrivateKey, newDhPublicKey: &newDhPublicKey)
            }
            .flatMap { _ -> Result<ShieldChainStep, EcliptixProtocolFailure> in
                return ShieldChainStep.create(
                    stepType: .receiver,
                    initialChainKey: &localReceiverCk!,
                    initialDhPrivateKey: &persistentPrivKeyBytes,
                    initialDhPublicKey: &persistentDhPublicKey
                )
            }
            .map { receivingStepLocal in
                rootKeyHandle = tempRootHandle
                tempRootHandle = nil
                
                receivingStep = receivingStepLocal
                tempReceivingStep = nil
                
                peerDhPublicKey = peerDhPublicCopy
                peerDhPublicCopy = nil
                
                debugPrint("[ShieldSession] Chain and DH keys finalized for session \(id)")
                return Unit.value
            }
            .mapError { err in
                debugPrint("[ShieldSession] Error finalizing chain and DH keys: \(err.localizedDescription)")
                tempRootHandle?.dispose()
                tempReceivingStep?.dispose()
                return err
            }
    }
    
    internal func prepareNextSendMessage() -> Result<(messageKey: ShieldMessageKey, includeDhKey: Bool), EcliptixProtocolFailure> {
        var sendingStepLocal: ShieldChainStep?
        var messageKey: ShieldMessageKey?
        var clonedMessageKey: ShieldMessageKey?
        var keyMaterial: Data? = nil
        var includeDhKey = false

        defer {
            _ = ConnectSession.wipeIfNotNil(&keyMaterial)
        }

        debugPrint("[ShieldSession] Preparing next send message for session \(id)")
        
        return checkDisposed()
            .flatMap { _ in self.ensureNotExpired() }
            .flatMap { _ in self.ensureSendingStepInitialized() }
            .flatMap { step -> Result<(performedRatchet: Bool, receivedNewKey: Bool), EcliptixProtocolFailure> in
                sendingStepLocal = step
                return self.maybePerformSendingDhRatchet(sendingStep: sendingStepLocal!)
            }
            .flatMap { ratchetInfo -> Result<UInt32, EcliptixProtocolFailure> in
                includeDhKey = ratchetInfo.performedRatchet
                debugPrint("[ShieldSession] DH Ratchet performed: \(includeDhKey)")
                return sendingStepLocal!.getCurrentIndex()
                    .map { currentIndex in
                        let nextIndex: UInt32 = currentIndex + 1
                        debugPrint("[ShieldSession] Preparing message for next index: \(nextIndex)")
                        return nextIndex
                    }
            }
            .flatMap { nextIndex -> Result<(messageKey: ShieldMessageKey, includeDhKey: Bool), EcliptixProtocolFailure> in
                sendingStepLocal!.getOrDeriveKeyFor(targetIndex: nextIndex, messageKeys: &messageKeys)
                    .flatMap { derivedKey in
                        messageKey = derivedKey
                        return sendingStepLocal!.setCurrentIndex(nextIndex)
                            .map { _ in derivedKey }
                    }
                    .flatMap { originalKey in
                        keyMaterial = Data(count: Constants.aesKeySize)
                        return originalKey.readKeyMaterial(into: &keyMaterial!)
                            .flatMap { _ in ShieldMessageKey.new(index: originalKey.index, keyMaterial: &keyMaterial!) }
                            .map { clone in
                                clonedMessageKey = clone
                                debugPrint("[ShieldSession] Derived message key for index: \(clone.index)")
                                sendingStepLocal!.pruneOldKeys(messageKeys: &messageKeys)
                                return (messageKey: clone, includeDhKey: includeDhKey)
                            }
                    }
            }
    }
    
    internal func processReceivedMessage(receivedIndex: UInt32, receivedDhPublicKeyBytes: inout Data?) -> Result<ShieldMessageKey, EcliptixProtocolFailure> {
        var receivingStepLocal: ShieldChainStep?
        var peerDhPublicCopy: Data? = nil
        var messageKey: ShieldMessageKey?

        defer {
            _ = Self.wipeIfNotNil(&peerDhPublicCopy)
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
    
    private func deriveInitialChainKeys(rootKey: inout Data) -> Result<(senderCk: Data, receiverCk: Data), EcliptixProtocolFailure> {
        var initiatorSenderChainKey: Data? = nil
        var responderSenderChainKey: Data? = nil

        defer {
            _ = Self.wipeIfNotNil(&initiatorSenderChainKey)
            _ = Self.wipeIfNotNil(&responderSenderChainKey)
        }

        debugPrint("[ShieldSession] Deriving initial chain keys from root key: \(rootKey.hexEncodedString())")

        return Result<(senderCk: Data, receiverCk: Data), EcliptixProtocolFailure>.Try{
            var sendSpan = Data(repeating: 0, count: Constants.x25519KeySize)
            var recvSpan = Data(repeating: 0, count: Constants.x25519KeySize)

            var saltHkdfSend: Data? = nil
            let hkdfSend = try HkdfSha256(ikm: &rootKey, salt: &saltHkdfSend)
            try hkdfSend.expand(info: Self.initialSenderChainInfo, output: &sendSpan)

            var saltHkdfRecv: Data? = nil
            let hkdfRecv = try HkdfSha256(ikm: &rootKey, salt: &saltHkdfRecv)
            try hkdfRecv.expand(info: Self.initialReceiverChainInfo, output: &recvSpan)

            initiatorSenderChainKey = sendSpan
            responderSenderChainKey = recvSpan

            let localSenderCk = isInitiator ? initiatorSenderChainKey! : responderSenderChainKey!
            let localReceiverCk = isInitiator ? responderSenderChainKey! : initiatorSenderChainKey!

            initiatorSenderChainKey = nil
            responderSenderChainKey = nil

            return (senderCk: localSenderCk, receiverCk: localReceiverCk)
        }.mapError { error in
            EcliptixProtocolFailure.deriveKey("Failed to derive initial chain keys.", inner: error)
        }
    }
    
    private func ensureSendingStepInitialized() -> Result<ShieldChainStep, EcliptixProtocolFailure> {
        return checkDisposed().flatMap { _ in
            return sendingStep != nil ? .success(sendingStep!) : .failure(EcliptixProtocolFailure.generic("Sending chain step not initialized."))
        }
    }
    
    private func ensureReceivingStepInitialized() -> Result<ShieldChainStep, EcliptixProtocolFailure> {
        return checkDisposed().flatMap { _ in
            if receivingStep != nil {
                return .success(receivingStep!)
            } else {
                return .failure(EcliptixProtocolFailure.generic("Receiving chain step not initialized."))
            }
        }
    }
    
    private func maybePerformSendingDhRatchet(sendingStep: ShieldChainStep) -> Result<(performedRatchet: Bool, receivedNewKey: Bool), EcliptixProtocolFailure> {
        return sendingStep.getCurrentIndex().flatMap { currentIndex in
            let shouldRatchet = (Int(currentIndex) + 1) % ConnectSession.dhRotationInterval == 0 || receivedNewDhKey
            let currentReceivedNewDhKey = receivedNewDhKey
            debugPrint("[ShieldSession] Checking if DH ratchet needed. Current Index: \(currentIndex), Received New DH Key: \(receivedNewDhKey), Should Ratchet: \(shouldRatchet)")

            if shouldRatchet {
                return performDhRatchet(isSender: true, receivedDhPublicKeyBytes: nil)
                    .map { _ in
                        receivedNewDhKey = false
                        debugPrint("[ShieldSession] DH ratchet performed for sending.")
                        return (performedRatchet: true, receivedNewKey: currentReceivedNewDhKey)
                    }
            }

            return .success((performedRatchet: false, receivedNewKey: currentReceivedNewDhKey))
        }
    }
    
    private func maybePerformReceivingDhRatchet(
        receivingStep: ShieldChainStep,
        receivedDhPublicKeyBytes: inout Data?
    ) -> Result<Unit, EcliptixProtocolFailure> {
        if receivedDhPublicKeyBytes == nil {
            return .success(Unit.value)
        }

        do {
            let keysDiffer = peerDhPublicKey == nil || peerDhPublicKey != receivedDhPublicKeyBytes
            debugPrint("[ShieldSession] Checking DH key difference. Peer DH Key: \(peerDhPublicKey!.hexEncodedString()), Received: \(receivedDhPublicKeyBytes!.hexEncodedString())")

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
        var currentRootKey: Data? = nil
        var newRootKey: Data? = nil
        var newChainKeyForTargetStep: Data? = nil
        var hkdfOutput: Data? = nil
        var localPrivateKeyBytes: Data? = nil
        var newEphemeralSkHandle: SodiumSecureMemoryHandle? = nil
        var newEphemeralPublicKey: Data? = nil

        defer {
            _ = ConnectSession.wipeIfNotNil(&dhSecret)
            _ = ConnectSession.wipeIfNotNil(&currentRootKey)
            _ = ConnectSession.wipeIfNotNil(&newRootKey)
            _ = ConnectSession.wipeIfNotNil(&hkdfOutput)
            _ = ConnectSession.wipeIfNotNil(&localPrivateKeyBytes)
            _ = ConnectSession.wipeIfNotNil(&newEphemeralPublicKey)
            newEphemeralSkHandle?.dispose()
        }

        do {
            debugPrint("[ShieldSession] Performing DH ratchet for session \(id), IsSender: \(isSender)")

            let initailCheck = checkDisposed().flatMap { _ in
                return rootKeyHandle!.isInvalid == false ? .success(Unit.value) : .failure(.generic("Root key handle not initialized or invalid."))
            }
            if initailCheck.isErr {
                return initailCheck
            }

            let dhResult: Result<Data, EcliptixProtocolFailure>

            if isSender {
                if sendingStep == nil {
                    return .failure(.generic("Sending step not initialized for DH ratchet."))
                }
                if peerDhPublicKey == nil {
                    return .failure(.generic("Peer DH public key not available for sender DH ratchet."))
                }

                let ephResult = Self.generateX25519KeyPair(keyPurpose: "Ephemeral DH Ratchet")
                if ephResult.isErr {
                    return .failure(try ephResult.unwrapErr())
                }
                
                newEphemeralSkHandle = try ephResult.unwrap().skHandle
                newEphemeralPublicKey = try ephResult.unwrap().pk
                debugPrint("[ShieldSession] New Ephemeral Public Key: \(newEphemeralPublicKey!.hexEncodedString())")
                
                dhResult = newEphemeralSkHandle!.readBytes(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
                    .flatMap { ephPrivBytes in
                        localPrivateKeyBytes = ephPrivBytes
                        debugPrint("[ShieldSession] Ephemeral Private Key: \(localPrivateKeyBytes!.hexEncodedString())")
                        return Result<Data, EcliptixProtocolFailure>.Try {
                            return try ScalarMult.mult(localPrivateKeyBytes!, peerDhPublicKey!)
                        }.mapError { error in
                            .deriveKey("Sender DH calculation failed.", inner: error)
                        }
                    }
            } else {
                if receivingStep == nil {
                    return .failure(.generic("Receiving step not initialized for DH ratchet."))
                }
                
                if receivedDhPublicKeyBytes!.count != Constants.x25519PublicKeySize {
                    return .failure(.invalidInput("Received DH public key is missing or invalid for receiver DH ratchet."))
                }

                debugPrint("[ShieldSession] Using current sending DH private key for receiver ratchet.")
                dhResult = currentSendingDhPrivateKeyHandle!.readBytes(length: Constants.x25519PrivateKeySize)
                    .mapSodiumFailure()
                    .flatMap { persistPrivBytes in
                        localPrivateKeyBytes = persistPrivBytes
                        debugPrint("[ShieldSession] Private Key: \(localPrivateKeyBytes!.hexEncodedString())")
                        return Result<Data, EcliptixProtocolFailure>.Try {
                            return try ScalarMult.mult(localPrivateKeyBytes!, receivedDhPublicKeyBytes!)
                        }.mapError { error in
                            .deriveKey("Reciever DH calculation failed.", inner: error)
                        }
                    }
            }

            _ = Self.wipeIfNotNil(&localPrivateKeyBytes)
            localPrivateKeyBytes = nil
            if dhResult.isErr {
                newEphemeralSkHandle?.dispose()
                return .failure(try dhResult.unwrapErr())
            }
            
            dhSecret = try dhResult.unwrap()
            debugPrint("[ShieldSession] DH Secret: \(dhSecret!.hexEncodedString())")

            let finalResult = rootKeyHandle!.readBytes(length: Constants.x25519KeySize)
                .mapSodiumFailure()
                .flatMap { rkBytes -> Result<Unit, EcliptixProtocolFailure> in
                    currentRootKey = rkBytes
                    debugPrint("[ShieldSession] Current Root Key: \(currentRootKey!.hexEncodedString())")
                    hkdfOutput = Data(count: Constants.x25519KeySize * 2)
                    
                    return Result<Unit, EcliptixProtocolFailure>.Try {
                        let hkdf = try HkdfSha256(ikm: &dhSecret!, salt: &currentRootKey)
                        try hkdf.expand(info: ConnectSession.dhRatchetInfo, output: &hkdfOutput!)
                        
                        return Unit.value
                    }.mapError { error in
                        .deriveKey("HKDF expansion failed during DH ratchet.", inner: error)
                    }
                }
                .flatMap { _ -> Result<Unit, EcliptixProtocolFailure> in
                    newRootKey = hkdfOutput!.prefix(Constants.x25519KeySize)
                    newChainKeyForTargetStep = hkdfOutput!.dropFirst(Constants.x25519KeySize).prefix(Constants.x25519KeySize)
                    debugPrint("[ShieldSession] New Root Key: \(newRootKey!.hexEncodedString())")
                    debugPrint("[ShieldSession] New Chain Key: \(newChainKeyForTargetStep!.hexEncodedString())")
                    return newRootKey!.withUnsafeBytes { bufferPointer in
                        rootKeyHandle!.write(data: bufferPointer).mapSodiumFailure()
                    }
                }
                .flatMap { _ -> Result<Unit, EcliptixProtocolFailure> in
                    return Result<Unit, EcliptixProtocolFailure>.Try {
                        if isSender {
                            let privateKeyResult = newEphemeralSkHandle!.readBytes(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
                            if privateKeyResult.isErr {
                                throw try privateKeyResult.unwrapErr()
                            }
                            var newDhPrivateKeyBytes: Data? = try privateKeyResult.unwrap()
                            debugPrint("[ShieldSession] Updating sending step with new DH keys.")
                            currentSendingDhPrivateKeyHandle?.dispose()
                            currentSendingDhPrivateKeyHandle = newEphemeralSkHandle
                            newEphemeralSkHandle = nil
                            
                            let result = sendingStep!.updateKeysAfterDhRatchet(newChainKey: &newChainKeyForTargetStep!, newDhPrivateKey: &newDhPrivateKeyBytes, newDhPublicKey: &newEphemeralPublicKey)

                            if result.isErr {
                                throw try result.unwrapErr()
                            }

                            return Unit.value
                        }
                        
                        debugPrint("[ShieldSession] Updating receiving step.")
                        var newDhPrivateKey: Data? = nil
                        var newDhPublicKey: Data? = nil
                        let result = receivingStep!.updateKeysAfterDhRatchet(newChainKey: &newChainKeyForTargetStep!, newDhPrivateKey: &newDhPrivateKey, newDhPublicKey: &newDhPublicKey)

                        if result.isErr {
                            throw try result.unwrapErr()
                        }

                        return Unit.value
                    }
                }
                .map { _ in
                    if !isSender {
                        _ = Self.wipeIfNotNil(&peerDhPublicKey)
                        peerDhPublicKey = Data(receivedDhPublicKeyBytes!)
                    }
                    
                    receivedNewDhKey = false
                    
                    clearMessageKeyCache()
                    debugPrint("[ShieldSession] DH ratchet completed.")
                    return Unit.value
                }
                .mapError { error in
                    debugPrint("[ShieldSession] Error during DH ratchet: \(error.message)")
                    if isSender {
                        newEphemeralSkHandle?.dispose()
                    }
                    return error
                }
            
            return finalResult
        } catch {
            return .failure(EcliptixProtocolFailure.generic("Unexpected error during perform DhRatchet.", inner: error))
        }
    }


    internal func generateNextNonce() -> Result<Data, EcliptixProtocolFailure> {
        return checkDisposed().map { _ in
            var nonceBuffer = Data(count: ConnectSession.aesGcmNonceSize)
            
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
            let expired = Date().timeIntervalSince(createdAt) > ConnectSession.sessionTimeout
            print("[ShieldSession] Checking expiration for session \(id). Expired: \(expired)")
            
            return expired
                ? .failure(EcliptixProtocolFailure.generic("Session \(id) has expired."))
                : .success(Unit.value)
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
            return .failure(EcliptixProtocolFailure.objectDisposed("ConnectSession"))
        } else {
            return .success(Unit())
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
        _ = ConnectSession.wipeIfNotNil(&peerDhPublicKey)
        _ = ConnectSession.wipeIfNotNil(&persistentDhPublicKey)
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
