//
//  EcliptixSystemIdentityKeys.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 27.05.2025.
//

import Foundation
import Sodium
import Clibsodium

final class EcliptixSystemIdentityKeys {
    private let ed25519SecretKeyHandle: SodiumSecureMemoryHandle
    private let identityX25519SecretKeyHandle: SodiumSecureMemoryHandle
    private let signedPreKeySecretKeyHandle: SodiumSecureMemoryHandle

    private var ephemeralSecretKeyHandle: SodiumSecureMemoryHandle?
    
    private var ed25519PublicKey: Data
    private let signedPreKeyId: UInt32
    private let signedPreKeyPublic: Data
    private let signedPreKeySignature: Data
    private var oneTimePreKeysInternal: [OneTimePreKeyLocal]
    private var ephemeralX25519PublicKey: Data?
    
    let identityX25519PublicKey: Data

    private var disposed: Bool = false

    private init(
        edSk: SodiumSecureMemoryHandle,
        edPk: inout Data,
        idSk: SodiumSecureMemoryHandle,
        idPk: inout Data,
        spkId: UInt32,
        spkSk: SodiumSecureMemoryHandle,
        spkPk: inout Data,
        spkSig: inout Data,
        opks: inout [OneTimePreKeyLocal]) {
            
        self.ed25519SecretKeyHandle = edSk
        self.ed25519PublicKey = edPk
        self.identityX25519SecretKeyHandle = idSk
        self.identityX25519PublicKey = idPk
        self.signedPreKeyId = spkId
        self.signedPreKeySecretKeyHandle = spkSk
        self.signedPreKeyPublic = spkPk
        self.signedPreKeySignature = spkSig
        self.oneTimePreKeysInternal = opks
        self.disposed = false
    }

    deinit {
        dispose()
    }
    
    public func dispose() {
        dispose(disposing: true)
    }
    
    public static func create(oneTimeKeyCount: UInt32) -> Result<EcliptixSystemIdentityKeys, EcliptixProtocolFailure> {
        if oneTimeKeyCount > UInt32(UInt32.max) {
            return .failure(.invalidInput("Requested one-time key count exceeds practical limits."))
        }

        var edSkHandle: SodiumSecureMemoryHandle? = nil
        var edPk: Data? = nil
        var idXSkHandle: SodiumSecureMemoryHandle? = nil
        var idXPk: Data? = nil
        var spkId: UInt32 = 0
        var spkSkHandle: SodiumSecureMemoryHandle? = nil
        var spkPk: Data? = nil
        var spkSig: Data? = nil
        var opks: [OneTimePreKeyLocal]? = nil

        let overallResult = generateEd25519Keys()
            .flatMap { edKeys -> Result<(skHandle: SodiumSecureMemoryHandle, pk: Data), EcliptixProtocolFailure> in
                edSkHandle = edKeys.skHandle
                edPk = edKeys.pk
                return generateX25519IdentityKeys()
            }
            .flatMap { idKeys -> Result<(skHandle: SodiumSecureMemoryHandle, pk: Data), EcliptixProtocolFailure> in
                idXSkHandle = idKeys.skHandle
                idXPk = idKeys.pk
                spkId = generateRandomUInt32()
                return generateX25519SignedPreKey(id: spkId)
            }
            .flatMap { spkKeys -> Result<Data, EcliptixProtocolFailure> in
                spkSkHandle = spkKeys.skHandle
                spkPk = spkKeys.pk
                return signSignedPreKey(edSkHandle: edSkHandle!, spkPk: &spkPk!)
            }
            .flatMap { signature -> Result<[OneTimePreKeyLocal], EcliptixProtocolFailure> in
                spkSig = signature
                return generateOneTimePreKeys(count: oneTimeKeyCount)
            }
            .flatMap { generatedOpks -> Result<EcliptixSystemIdentityKeys, EcliptixProtocolFailure> in
                opks = generatedOpks
                
                let material = EcliptixSystemIdentityKeys(edSk: edSkHandle!, edPk: &edPk!, idSk: idXSkHandle!, idPk: &idXPk!, spkId: spkId, spkSk: spkSkHandle!, spkPk: &spkPk!, spkSig: &spkSig!, opks: &opks!)
                
                return .success(material)
            }

        if overallResult.isErr {
            edSkHandle?.dispose()
            idXSkHandle?.dispose()
            spkSkHandle?.dispose()
            opks?.forEach { $0.dispose() }
        }
        
        return overallResult
    }

    
    public func createPublicBundle() -> Result<LocalPublicKeyBundle, EcliptixProtocolFailure> {
        if disposed {
            return .failure(.objectDisposed(String(describing: EcliptixSystemIdentityKeys.self)))
        }
        
        return Result<LocalPublicKeyBundle, EcliptixProtocolFailure>.Try {
            var opkRecords: [OneTimePreKeyRecord] = try oneTimePreKeysInternal.compactMap { opkLocal in
                let opkKeyCreateResult = OneTimePreKeyRecord.create(preKeyId: opkLocal.preKeyId, publicKey: opkLocal.publicKey)
                return opkKeyCreateResult.isOk ? try opkKeyCreateResult.unwrap() : nil
            }
            
            var internalBundle = InternalBundleData(
                identityEd25519: ed25519PublicKey,
                identityX25519: identityX25519PublicKey,
                signedPreKeyId: signedPreKeyId,
                signedPreKeyPublic: signedPreKeyPublic,
                signedPreKeySignature: signedPreKeySignature,
                oneTimePreKeys: opkRecords,
                ephemeralX25519: ephemeralX25519PublicKey)
            
            let localBundle = LocalPublicKeyBundle(&internalBundle)
            
            return localBundle
        }.mapError { error in
            .generic("Failed to create public key bundle.", inner: error)
        }
    }
    
    public func generateEphemeralKeyPair() {
        if disposed {
            _ = Result<Unit, EcliptixProtocolFailure>.failure(.objectDisposed(String(describing: EcliptixSystemIdentityKeys.self)))
            return
        }

        ephemeralSecretKeyHandle?.dispose()
        ephemeralSecretKeyHandle = nil
        
        if ephemeralX25519PublicKey != nil {
            _ = SodiumInterop.secureWipe(&ephemeralX25519PublicKey)
        }
        ephemeralX25519PublicKey = nil

        let generationResult = Self.generateX25519KeyPair(keyPurpose: "Ephemeral")
        
        _ = generationResult.map { keys in
            ephemeralSecretKeyHandle = keys.skHandle
            ephemeralX25519PublicKey = keys.pk
            return Unit.value
        }
    }

    
    public func x3dhDeriveSharedSecret(
        remoteBundle: LocalPublicKeyBundle,
        info: Data
    ) -> Result<SodiumSecureMemoryHandle, EcliptixProtocolFailure> {
        var ephemeralHandleUsed: SodiumSecureMemoryHandle? = nil
        var secureOutputHandle: SodiumSecureMemoryHandle? = nil
        
        var ephemeralSecretCopy: Data? = nil
        var identitySecretCopy: Data? = nil
        var dh1: Data? = nil
        var dh2: Data? = nil
        var dh3: Data? = nil
        var dh4: Data? = nil
        var dhConcatBytes: Data? = nil
        var hkdfOutput: Data? = nil
        
        var infoCopy: Data = info
        
        defer {
            ephemeralHandleUsed?.dispose()
            secureOutputHandle?.dispose()
            if infoCopy != nil {
                _ = SodiumInterop.secureWipe(&infoCopy)
            }
            if ephemeralSecretCopy != nil {
                _ = SodiumInterop.secureWipe(&ephemeralSecretCopy)
            }
            if identitySecretCopy != nil {
                _ = SodiumInterop.secureWipe(&identitySecretCopy)
            }
            if dh1 != nil {
                _ = SodiumInterop.secureWipe(&dh1)
            }
            if dh2 != nil {
                _ = SodiumInterop.secureWipe(&dh2)
            }
            if dh3 != nil {
                _ = SodiumInterop.secureWipe(&dh3)
            }
            if dh4 != nil {
                _ = SodiumInterop.secureWipe(&dh4)
            }
            if dhConcatBytes != nil {
                _ = SodiumInterop.secureWipe(&dhConcatBytes)
            }
            if hkdfOutput != nil {
                _ = SodiumInterop.secureWipe(&hkdfOutput)
            }
        }
        
        do {
            let validationResult: Result<Unit, EcliptixProtocolFailure> = checkDisposed()
                .flatMap { _ in Self.validateHkdfInfo(infoCopy)}
                .flatMap { _ in Self.validateRemoteBundle(remoteBundle) }
                .flatMap { _ in ensureLocalKeysValid() }
            
            if validationResult.isErr {
                return .failure(try validationResult.unwrapErr())
            }
            
            let processResult: Result<SodiumSecureMemoryHandle, EcliptixProtocolFailure> = ephemeralSecretKeyHandle!.readBytes(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
                .flatMap { ephBytes -> Result<Data, EcliptixProtocolFailure> in
                    ephemeralSecretCopy = ephBytes
                    return self.identityX25519SecretKeyHandle.readBytes(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
                }
                .flatMap { idBytes -> Result<(dh1: Data, dh2: Data, dh3: Data, dh4: Data?), EcliptixProtocolFailure> in
                    identitySecretCopy = idBytes
                    ephemeralHandleUsed = self.ephemeralSecretKeyHandle
                    self.ephemeralSecretKeyHandle = nil
                    
                    return Result<(dh1: Data, dh2: Data, dh3: Data, dh4: Data?), EcliptixProtocolFailure>.Try {
                        let dh1: Data = try ScalarMult.mult(ephemeralSecretCopy!, remoteBundle.identityX25519)
                        let dh2: Data = try ScalarMult.mult(ephemeralSecretCopy!, remoteBundle.signedPreKeyPublic)
                        let dh3: Data = try ScalarMult.mult(identitySecretCopy!, remoteBundle.signedPreKeyPublic)
                        var dh4: Data? = nil
                        
                        let remoteOpk: OneTimePreKeyRecord? = remoteBundle.oneTimePreKeys.first
                        
                        if remoteOpk?.publicKey.count == Constants.x25519PublicKeySize {
                            dh4 = try ScalarMult.mult(ephemeralSecretCopy!, remoteOpk!.publicKey)
                        }

                        return (dh1: dh1, dh2: dh2, dh3: dh3, dh4: dh4)
                    }.mapError { error in
                        .deriveKey("Failed during DH calculation", inner: error)
                    }
                }
                .flatMap { dhResult -> Result<Unit, EcliptixProtocolFailure> in
                    (dh1, dh2, dh3, dh4) = dhResult
                    dh1 = dhResult.dh1
                    dh2 = dhResult.dh2
                    dh3 = dhResult.dh3
                    dh4 = dhResult.dh4
                    
                    _ = SodiumInterop.secureWipe(&ephemeralSecretCopy)
                    ephemeralSecretCopy = nil
                    
                    _ = SodiumInterop.secureWipe(&identitySecretCopy)
                    identitySecretCopy = nil

                    dhConcatBytes = Self.concatenateDhResultsInCanonicalOrder(dh1: dh1!, dh2: dh2!, dh3: dh3!, dh4: dh4)

                    hkdfOutput = Data(count: Constants.x25519KeySize)
                    var capturedInfoCopy = infoCopy
                    
                    return Result<Unit, EcliptixProtocolFailure>.Try {
                        let f32 = Data(repeating: 0xFF, count: Constants.x25519KeySize)
                        var hkdfSaltSpan: Data? = Data(repeating: 0, count: Constants.x25519KeySize)
                        var ikm = Data()
                        ikm.append(f32)
                        ikm.append(dhConcatBytes!)
                        let hkdf = try HkdfSha256(ikm: &ikm, salt: &hkdfSaltSpan)
                        try hkdf.expand(info: capturedInfoCopy, output: &hkdfOutput!)
                        
                        return Unit.value
                    }.mapError { error in
                        .deriveKey("Failed during HKDF expansion (Bob).", inner: error)
                    }
                }
                .flatMap { _ -> Result<SodiumSecureMemoryHandle, EcliptixProtocolFailure> in
                    return SodiumSecureMemoryHandle.allocate(length: hkdfOutput!.count).mapSodiumFailure()
                        .flatMap { allocatedHandle in
                            return hkdfOutput!.withUnsafeBytes { bufferPointer in
                                allocatedHandle.write(data: bufferPointer).mapSodiumFailure().map { _ in allocatedHandle }
                            }
                        }
                }

            if processResult.isErr {
                return processResult
            }
            else {
                secureOutputHandle = try processResult.unwrap()
                let returnHandle = secureOutputHandle
                secureOutputHandle = nil
                return .success(returnHandle!)
            }
        } catch {
            return .failure(.unexpectedError("Unexpected error in \(String(describing: EcliptixSystemIdentityKeys.self)).", inner: error))
        }
    }
    
    
    public func calculateSharedSecretAsRecipient(
        remoteIdentityPublicKeyX: Data,
        remoteEphemeralPublicKeyX: Data,
        usedLocalOpkId: UInt32?,
        info: Data
    ) -> Result<SodiumSecureMemoryHandle, EcliptixProtocolFailure> {
        
        var secureOutputHandle: SodiumSecureMemoryHandle? = nil
        var identitySecretCopy: Data? = nil
        var signedPreKeySecretCopy: Data? = nil
        var oneTimePreKeySecretCopy: Data? = nil
        var dh1: Data? = nil, dh2: Data? = nil, dh3: Data? = nil, dh4: Data? = nil
        var dhConcatBytes: Data? = nil, hkdfOutput: Data? = nil
        var opkSecretHandle: SodiumSecureMemoryHandle? = nil
        var remoteIdentityCopy: Data? = nil
        var remoteEphemeralCopy: Data? = nil
        var infoCopy: Data? = nil
        
        defer {
            secureOutputHandle?.dispose()
            if remoteIdentityCopy != nil {
                _ = SodiumInterop.secureWipe(&remoteIdentityCopy)
            }
            if remoteEphemeralCopy != nil {
                _ = SodiumInterop.secureWipe(&remoteEphemeralCopy)
            }
            if identitySecretCopy != nil {
                _ = SodiumInterop.secureWipe(&identitySecretCopy)
            }
            if infoCopy != nil {
                _ = SodiumInterop.secureWipe(&infoCopy)
            }
            if identitySecretCopy != nil {
                _ = SodiumInterop.secureWipe(&identitySecretCopy)
            }
            if signedPreKeySecretCopy != nil {
                _ = SodiumInterop.secureWipe(&signedPreKeySecretCopy)
            }
            if oneTimePreKeySecretCopy != nil {
                _ = SodiumInterop.secureWipe(&oneTimePreKeySecretCopy)
            }
            if dh1 != nil {
                _ = SodiumInterop.secureWipe(&dh1)
            }
            if dh2 != nil {
                _ = SodiumInterop.secureWipe(&dh2)
            }
            if dh3 != nil {
                _ = SodiumInterop.secureWipe(&dh3)
            }
            if dh4 != nil {
                _ = SodiumInterop.secureWipe(&dh4)
            }
            if dhConcatBytes != nil {
                _ = SodiumInterop.secureWipe(&dhConcatBytes)
            }
            if hkdfOutput != nil {
                _ = SodiumInterop.secureWipe(&hkdfOutput)
            }
        }
        
        do {
            remoteIdentityCopy = remoteIdentityPublicKeyX
            remoteEphemeralCopy = remoteEphemeralPublicKeyX
            infoCopy = info
            
            let validationResult = checkDisposed()
                .flatMap { _ in Self.validateHkdfInfo(infoCopy) }
                .flatMap { _ in Self.validateRemoteRecipientKeys(remoteIdentityPublicKeyX: remoteIdentityCopy, remoteEphemeralPublicKeyX: remoteEphemeralCopy) }
                .flatMap { _ in ensureLocalRecipientKeysValid() }
            
            if validationResult.isErr {
                return .failure(try validationResult.unwrapErr())
            }
            
            if usedLocalOpkId != nil {
                let findOpkResult = findLocalOpkHandle(usedLocalOpkId!)
                if findOpkResult.isErr {
                    return .failure(try findOpkResult.unwrapErr())
                }
                opkSecretHandle = try findOpkResult.unwrap()
            }
            
            let capturedRemoteIdentity: Data = remoteIdentityCopy!
            let capturedRemoteEphemeral: Data = remoteEphemeralCopy!
            let capturedInfo: Data = infoCopy!
            
            let processResult = self.identityX25519SecretKeyHandle.readBytes(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
                .flatMap { idBytes -> Result<Data, EcliptixProtocolFailure> in
                    identitySecretCopy = idBytes
                    return self.signedPreKeySecretKeyHandle.readBytes(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
                }
                .flatMap { spkBytes -> Result<Unit, EcliptixProtocolFailure> in
                    signedPreKeySecretCopy = spkBytes
                    if opkSecretHandle != nil {
                        return opkSecretHandle!.readBytes(length: Constants.x25519PrivateKeySize).map { opkBytes -> Unit in
                            oneTimePreKeySecretCopy = opkBytes
                            return Unit.value
                        }.mapSodiumFailure()
                    }
                    
                    return .success(Unit.value)
                }
                .flatMap { _ -> Result<(dh1: Data , dh2: Data, dh3: Data, dh4: Data?), EcliptixProtocolFailure> in
                    return Result<(dh1: Data , dh2: Data, dh3: Data, dh4: Data?), EcliptixProtocolFailure>.Try {
                        let dh1: Data = try ScalarMult.mult(identitySecretCopy!, capturedRemoteEphemeral)
                        let dh2: Data = try ScalarMult.mult(signedPreKeySecretCopy!, capturedRemoteEphemeral)
                        let dh3: Data = try ScalarMult.mult(signedPreKeySecretCopy!, capturedRemoteIdentity)
                        let dh4: Data? = oneTimePreKeySecretCopy != nil
                            ? try ScalarMult.mult(oneTimePreKeySecretCopy!, capturedRemoteEphemeral)
                            : nil
                        
                        return (dh1: dh1, dh2: dh2, dh3: dh3, dh4: dh4)
                    }.mapError { error in
                        .deriveKey("Failed during DH calculation (Bob).", inner: error)
                    }
                }
                .flatMap { dhResult -> Result<Unit, EcliptixProtocolFailure> in
                    dh1 = dhResult.dh1
                    dh2 = dhResult.dh2
                    dh3 = dhResult.dh3
                    dh4 = dhResult.dh4
                    _ = SodiumInterop.secureWipe(&identitySecretCopy)
                    identitySecretCopy = nil
                    _ = SodiumInterop.secureWipe(&signedPreKeySecretCopy)
                    signedPreKeySecretCopy = nil
                    if oneTimePreKeySecretCopy != nil {
                        _ = SodiumInterop.secureWipe(&oneTimePreKeySecretCopy!)
                        oneTimePreKeySecretCopy = nil
                    }
                    
                    dhConcatBytes = Self.concatenateDhResultsInCanonicalOrder(dh1: dh1!, dh2: dh2!, dh3: dh3!, dh4: dh4)
                    hkdfOutput = Data(count: Constants.x25519KeySize)
                    
                    return Result<Unit, EcliptixProtocolFailure>.Try {
                        let f32 = Data(repeating: 0xFF, count: Constants.x25519KeySize)
                        var hkdfSaltSpan: Data? = Data(repeating: 0, count: Constants.x25519KeySize)
                        var ikm = Data()
                        ikm.append(f32)
                        ikm.append(dhConcatBytes!)
                        let hkdf = try HkdfSha256(ikm: &ikm, salt: &hkdfSaltSpan)
                        try hkdf.expand(info: capturedInfo, output: &hkdfOutput!)
                        
                        return Unit.value
                    }.mapError { error in
                        .deriveKey("Failed during HKDF expansion (Bob).", inner: error)
                    }
                }
                .flatMap { _ in
                    return SodiumSecureMemoryHandle.allocate(length: hkdfOutput!.count)
                        .flatMap { allocatedHandle in
                            return hkdfOutput!.withUnsafeBytes { bufferPointer in
                                allocatedHandle.write(data: bufferPointer).map { _ in allocatedHandle }
                            }
                            
                        }.mapSodiumFailure()
                }
            
            if processResult.isErr {
                return processResult
            }
            else {
                secureOutputHandle = try processResult.unwrap()
                let returnHandle: SodiumSecureMemoryHandle = secureOutputHandle!
                secureOutputHandle = nil
                return .success(returnHandle)
            }
        } catch {
            return .failure(.deriveKey("Unhandled error during shared secret calculation (Bob).", inner: error))
        }

        
//        // Перевірки на коректність та валідність
//        let validationResult = checkDisposed()
//            .flatMap { _ in Self.validateHkdfInfo(info) }
//            .flatMap { _ in Self.validateRemoteRecipientKeys(remoteIdentityPublicKeyX: remoteIdentityPublicKeyX, remoteEphemeralPublicKeyX: remoteEphemeralPublicKeyX) }
//            .flatMap { _ in ensureLocalRecipientKeysValid() }
//        
//        if case .failure(let err) = validationResult {
//            return .failure(err)
//        }
//        
//        if let opkId = usedLocalOpkId {
//            let opkResult = findLocalOpkHandle(UInt32(opkId))
//            if case .failure(let err) = opkResult {
//                return .failure(err)
//            }
//            opkSecretHandle = try! opkResult.unwrap()
//        }
//        
//        let capturedRemoteIdentity = remoteIdentityPublicKeyX
//        let capturedRemoteEphemeral = remoteEphemeralPublicKeyX
//        let capturedInfo = info
//        
//        let processResult = identityX25519SecretKeyHandle.readBytes(length: Constants.x25519PrivateKeySize)
//            .flatMap { idBytes -> Result<Data, ShieldFailure> in
//                identitySecretCopy = idBytes
//                return signedPreKeySecretKeyHandle.readBytes(length: Constants.x25519PrivateKeySize)
//            }
//            .flatMap { spkBytes -> Result<Void, ShieldFailure> in
//                signedPreKeySecretCopy = spkBytes
//                if let opkHandle = opkSecretHandle {
//                    return opkHandle.readBytes(length: Constants.x25519PrivateKeySize).map {
//                        oneTimePreKeySecretCopy = $0
//                    }
//                }
//                return .success(())
//            }
//            .flatMap { _ -> Result<(Data, Data, Data, Data?), ShieldFailure> in
//                do {
//                    let dh1 = try ScalarMult.mult(identitySecretCopy!, capturedRemoteEphemeral)
//                    let dh2 = try ScalarMult.mult(signedPreKeySecretCopy!, capturedRemoteEphemeral)
//                    let dh3 = try ScalarMult.mult(signedPreKeySecretCopy!, capturedRemoteIdentity)
//                    let dh4 = oneTimePreKeySecretCopy != nil ? try ScalarMult.mult(oneTimePreKeySecretCopy!,  capturedRemoteEphemeral) : nil
//                    return .success((dh1, dh2, dh3, dh4))
//                } catch {
//                    return .failure(.deriveKey("Failed during DH calculation (Bob).", inner: error))
//                }
//            }
//            .flatMap { (d1, d2, d3, d4) -> Result<Void, ShieldFailure> in
//                dh1 = d1; dh2 = d2; dh3 = d3; dh4 = d4
//                _ = SodiumInterop.secureWipe(&identitySecretCopy)
//                _ = SodiumInterop.secureWipe(&signedPreKeySecretCopy)
//                identitySecretCopy = nil; signedPreKeySecretCopy = nil
//                if oneTimePreKeySecretCopy != nil {
//                    _ = SodiumInterop.secureWipe(&oneTimePreKeySecretCopy)
//                    oneTimePreKeySecretCopy = nil
//                }
//                dhConcatBytes = Self.concatenateDhResultsInCanonicalOrder(dh1: dh1!, dh2: dh2!, dh3: dh3!, dh4: dh4)
//                hkdfOutput = Data(repeating: 0, count: Constants.x25519KeySize)
//                return Result {
//                    let f32 = Data(repeating: 0xFF, count: Constants.x25519KeySize)
//                    let ikm = f32 + dhConcatBytes!
//                    let hkdf = try HkdfSha256(ikm: ikm, salt: Data(repeating: 0, count: Constants.x25519KeySize))
//                    try hkdf.expand(info: capturedInfo, output: &hkdfOutput!)
//                }.mapError { error in
//                    .deriveKey("Failed during HKDF expansion (Bob).", inner: error)
//                }
//            }
//            .flatMap { _ -> Result<SodiumSecureMemoryHandle, ShieldFailure> in
//                return SodiumSecureMemoryHandle.allocate(length: hkdfOutput!.count)
//                    .flatMap { handle in
//                        handle.write(data: hkdfOutput!.withUnsafeBytes { UnsafeRawBufferPointer($0) }).map { _ in handle }
//                    }
//            }
//        
//        switch processResult {
//        case .failure(let error):
//            return .failure(error)
//        case .success(let handle):
//            secureOutputHandle = nil
//            return .success(handle)
//        }
    }
    
    static func generateEd25519Keys() -> Result<(skHandle: SodiumSecureMemoryHandle, pk: Data), EcliptixProtocolFailure> {
        var skHandle: SodiumSecureMemoryHandle? = nil
        var skBytes: Data? = nil
        var pkBytes: Data? = nil
        
        defer {
            if skBytes != nil {
                _ = SodiumInterop.secureWipe(&skBytes)
            }
        }
        
        return Result<(skHandle: SodiumSecureMemoryHandle, pk: Data), EcliptixProtocolFailure>.Try {
            let edKeyPair = try PublicKeyAuth.generateKeyPair()
            skBytes = edKeyPair.privateKey
            pkBytes = edKeyPair.publicKey
            
            skHandle = try SodiumSecureMemoryHandle.allocate(length: Constants.ed25519SecretKeySize).unwrap()
            
            // Assume everything is successful
            let writeResult = skBytes!.withUnsafeBytes { bufferPointer in
                skHandle!.write(data: bufferPointer)
            }

            return (skHandle: skHandle!, pk: pkBytes!)
        }.mapError { ex in
            EcliptixProtocolFailure.keyGeneration("Failed to generate Ed25519 key pair.", inner: ex)
        }
    }

    static func generateX25519IdentityKeys() -> Result<(skHandle: SodiumSecureMemoryHandle, pk: Data), EcliptixProtocolFailure> {
        generateX25519KeyPair(keyPurpose: "Identity")
    }

    static func generateX25519SignedPreKey(id: UInt32) -> Result<(skHandle: SodiumSecureMemoryHandle, pk: Data), EcliptixProtocolFailure> {
        generateX25519KeyPair(keyPurpose: "Signed PreKey (ID: \(id))")
    }

    
    static func generateX25519KeyPair(keyPurpose: String) -> Result<(skHandle: SodiumSecureMemoryHandle, pk: Data), EcliptixProtocolFailure> {
        var skHandle: SodiumSecureMemoryHandle? = nil
        var skBytes: Data? = nil
        var pkBytes: Data? = nil
        var tempPrivCopy: Data? = nil
        
        do {
            let allocResult = SodiumSecureMemoryHandle.allocate(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
            if allocResult.isErr {
                return .failure(try allocResult.unwrapErr())
            }
            
            skHandle = try allocResult.unwrap()
            
            // Generate random private key bytes
            guard let randomBytes = Sodium().randomBytes.buf(length: Constants.x25519PrivateKeySize) else {
                return .failure(.generic("Failed to generate random bytes for private key"))
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
            
            // Derive public key from private key
            let deriveResult = Result<Data, EcliptixProtocolFailure>.Try {
                try ScalarMult.base(&tempPrivCopy!)
            }.mapError { ex in
                EcliptixProtocolFailure.deriveKey("Failed to derive \(keyPurpose) public key.", inner: ex)
            }
            
            _ = SodiumInterop.secureWipe(&tempPrivCopy)
            tempPrivCopy = nil
            
            if deriveResult.isErr {
                skHandle?.dispose()
                return .failure(try deriveResult.unwrapErr())
            }
            
            var pkBytes = try deriveResult.unwrap()
            if pkBytes.count != Constants.x25519PublicKeySize {
                skHandle?.dispose()
                _ = SodiumInterop.secureWipe(&pkBytes)
                return .failure(.deriveKey("Derived \(keyPurpose) public key has incorrect size."))
            }
            
            return .success((skHandle: skHandle!, pk: pkBytes))
        } catch {
            skHandle?.dispose()
            _ = SodiumInterop.secureWipe(&skBytes)
            _ = SodiumInterop.secureWipe(&tempPrivCopy)
            return .failure(.keyGeneration("Unexpected error generating \(keyPurpose) key pair.", inner: error))
        }
    }

    
    static func signSignedPreKey(edSkHandle: SodiumSecureMemoryHandle, spkPk: inout Data) -> Result<Data, EcliptixProtocolFailure> {
        var tempEdSignKeyCopy: Data?
        
        defer {
            if tempEdSignKeyCopy != nil {
                _ = SodiumInterop.secureWipe(&tempEdSignKeyCopy)
            }
        }
        
        do {
            tempEdSignKeyCopy = Data(count: Constants.ed25519SecretKeySize)
            
            let readResult = tempEdSignKeyCopy!.withUnsafeMutableBytes { destPtr in
                edSkHandle.read(into: destPtr).mapSodiumFailure()
            }
            if readResult.isErr {
                return .failure(try readResult.unwrapErr())
            }
            
            let signResult = Result<Data, EcliptixProtocolFailure>.Try {
                try PublicKeyAuth.signDetached(message: &spkPk, secretKey: &tempEdSignKeyCopy!)
            }.mapError { error in
                return EcliptixProtocolFailure.generic("Failed to sign signed prekey public key.", inner: error)
            }
            
            if signResult.isErr {
                return signResult
            }
            var signature = try signResult.unwrap()
            
            if signature.count != Constants.ed25519SignatureSize {
                _ = SodiumInterop.secureWipe(&signature)
                return .failure(.generic("Generated SPK signature has incorrect size (\(signature.count))"))
            }
            
            return .success(signature)
        } catch {
            return .failure(.unexpectedError("Unexpected error during sign signed pre key", inner: error))
        }
    }

    static func generateOneTimePreKeys(count: UInt32) -> Result<[OneTimePreKeyLocal], EcliptixProtocolFailure> {
        if count == 0 {
            return .success([])
        }
        
        var opks: [OneTimePreKeyLocal] = []
        var usedIds = Set<UInt32>()
        var idCounter: UInt32 = 2
        
        do {
            for _ in 0..<count {
                var id = idCounter
                idCounter += 1
                
                while usedIds.contains(id) {
                    id = generateRandomUInt32()
                }
                
                usedIds.insert(id)
                
                let opkResult = OneTimePreKeyLocal.generate(preKeyId: id)
                if opkResult.isErr {
                    for generatedOpk in opks {
                        generatedOpk.dispose()
                    }
                    return .failure(try opkResult.unwrapErr())
                }
                
                opks.append(try opkResult.unwrap())
            }
            
            return .success(opks)
        } catch {
            for generatedOpk in opks {
                generatedOpk.dispose()
            }
            return .failure(.keyGeneration("Unexpected error generation one-time prekeys.", inner: error))
        }
    }

    
    private static func generateRandomUInt32() -> UInt32 {
        guard let randomBytes = Sodium().randomBytes.buf(length: MemoryLayout<UInt32>.size) else {
            return 0
        }
        return randomBytes.withUnsafeBytes { ptr in
            ptr.load(as: UInt32.self)
        }
    }
    
    private func checkDisposed() -> Result<Unit, EcliptixProtocolFailure> {
        return disposed
            ? .failure(.objectDisposed(String(describing: EcliptixSystemIdentityKeys.self)))
            : .success(Unit.value)
    }
    
    private static func validateHkdfInfo(_ infoCopy: Data?) -> Result<Unit, EcliptixProtocolFailure> {
        return infoCopy == nil || infoCopy!.isEmpty ? .failure(.deriveKey("HKDF info cannot be empty.")) : .success(Unit.value)
    }
    
    private static func validateRemoteBundle(_ remoteBundle: LocalPublicKeyBundle?) -> Result<Unit, EcliptixProtocolFailure> {
        if remoteBundle == nil {
            return .failure(.invalidInput("Remote bundle cannot be null."))
        }
        if remoteBundle!.identityX25519.count != Constants.x25519PublicKeySize {
            return .failure(.peerPubKey("Invalid remote IdentityX25519 key."))
        }
        if remoteBundle!.signedPreKeyPublic.count != Constants.x25519PublicKeySize {
            return .failure(.peerPubKey("Invalid remote SignedPreKeyPublic key."))
        }
        return .success(Unit.value)
    }

    private func ensureLocalKeysValid() -> Result<Unit, EcliptixProtocolFailure> {
        if ephemeralSecretKeyHandle == nil || ephemeralSecretKeyHandle!.isInvalid {
            return .failure(.prepareLocal("Local ephemeral key is missing or invalid."))
        }
        if identityX25519SecretKeyHandle.isInvalid {
            return .failure(.prepareLocal("Local identity key is missing or invalid."))
        }
        return .success(Unit.value)
    }
    
    private static func concatenateDhResultsInCanonicalOrder(
        dh1: Data, // dhInitiatorEphResponderId
        dh2: Data, // dhInitiatorEphResponderSpk
        dh3: Data, // dhInitiatorIdResponderSpk
        dh4: Data? // dhInitiatorEphResponderOpk
    ) -> Data {
        var result = Data()
        result.append(dh1)
        result.append(dh2)
        result.append(dh3)
        if let dh4 = dh4 {
            result.append(dh4)
        }
        return result
    }
    
    public static func verifyRemoteSpkSignature(
        remoteIdentityEd25519: Data,
        remoteSpkPublic: Data,
        remoteSpkSignature: Data
    ) -> Result<Bool, EcliptixProtocolFailure> {
        var identityCopy: Data? = nil
        var spkPublicCopy: Data? = nil
        var signatureCopy: Data? = nil
        defer {
            _ = SodiumInterop.secureWipe(&identityCopy)
            _ = SodiumInterop.secureWipe(&spkPublicCopy)
            _ = SodiumInterop.secureWipe(&signatureCopy)
        }
        
        identityCopy = remoteIdentityEd25519
        spkPublicCopy = remoteSpkPublic
        signatureCopy = remoteSpkSignature
        
        guard identityCopy!.count == Constants.ed25519PublicKeySize else {
            return .failure(.peerPubKey("Invalid remote Ed25519 identity key length (\(identityCopy!.count))."))
        }
        
        guard spkPublicCopy!.count == Constants.x25519PublicKeySize else {
            return .failure(.peerPubKey("Invalid remote Signed PreKey public key length (\(spkPublicCopy!.count))."))
        }
        
        guard signatureCopy!.count == Constants.ed25519SignatureSize else {
            return .failure(.handshake("Invalid remote Signed PreKey signature length (\(signatureCopy!.count))."))
        }
        
        let capturedIdentity = identityCopy!
        let capturedSpkPublic = spkPublicCopy!
        let capturedSignature = signatureCopy!
        
        return Result<Bool, EcliptixProtocolFailure>.Try {
            return try PublicKeyAuth.verifyDetached(signature: capturedSignature, message: capturedSpkPublic, publicKey: capturedIdentity)
        }.mapError { error in
            .handshake("Internal error during signature verification: \(error.localizedDescription)", inner: error)
        }
    }
    
    private static func validateRemoteRecipientKeys(
        remoteIdentityPublicKeyX: Data?,
        remoteEphemeralPublicKeyX: Data?
    ) -> Result<Unit, EcliptixProtocolFailure> {
        
        if remoteIdentityPublicKeyX?.count != Constants.x25519PublicKeySize {
            return .failure(.peerPubKey("Invalid remote Identity key length."))
        }
        
        if remoteEphemeralPublicKeyX?.count != Constants.x25519PublicKeySize {
            return .failure(.peerPubKey("Invalid remote Ephemeral key length."))
        }
        
        return .success(Unit())
    }
    
    private func ensureLocalRecipientKeysValid() -> Result<Unit, EcliptixProtocolFailure> {
        if identityX25519SecretKeyHandle.isInvalid {
            return .failure(.prepareLocal("Local identity key is missing or invalid."))
        }
        if signedPreKeySecretKeyHandle.isInvalid {
            return .failure(.prepareLocal("Local signed prekey is missing or invalid."))
        }
        return .success(Unit())
    }

    private func findLocalOpkHandle(_ opkId: UInt32) -> Result<SodiumSecureMemoryHandle?, EcliptixProtocolFailure> {
        for opk in oneTimePreKeysInternal where opk.preKeyId == opkId {
            if opk.privateKeyHandle.isInvalid {
                return .failure(.prepareLocal("Local OPK ID \(opkId) found but its handle is invalid."))
            }
            return .success(opk.privateKeyHandle)
        }
        return .failure(.handshake("Local OPK ID \(opkId) not found."))
    }
    
    private func dispose(disposing: Bool) {
        if disposed { return }
        
        if disposing {
            secureCleanupLogic()
        }
        
        disposed = true
    }
    
    private func secureCleanupLogic()
    {
        ed25519SecretKeyHandle.dispose();
        identityX25519SecretKeyHandle.dispose();
        signedPreKeySecretKeyHandle.dispose();
        ephemeralSecretKeyHandle?.dispose();
        
        for opk in oneTimePreKeysInternal {
            opk.dispose()
        }

        oneTimePreKeysInternal.removeAll();

        oneTimePreKeysInternal = [];
        ephemeralSecretKeyHandle = nil;
    }
}

struct PublicKeyAuth {
    /// Перевірка Ed25519 підпису (detached)
    static func verifyDetached(signature: Data, message: Data, publicKey: Data) throws -> Bool {
        // Перевірка довжини
        guard signature.count == Int(crypto_sign_BYTES) else {
            throw VerifyError.invalidSignatureLength(signature.count)
        }
        guard publicKey.count == Int(crypto_sign_PUBLICKEYBYTES) else {
            throw VerifyError.invalidPublicKeyLength(publicKey.count)
        }
        
        // Виклик C-функції
        let result = signature.withUnsafeBytes { sigRawBuffer in
            message.withUnsafeBytes { msgRawBuffer in
                publicKey.withUnsafeBytes { pkRawBuffer in
                    guard
                        let sigPtr = sigRawBuffer.bindMemory(to: UInt8.self).baseAddress,
                        let msgPtr = msgRawBuffer.bindMemory(to: UInt8.self).baseAddress,
                        let pkPtr = pkRawBuffer.bindMemory(to: UInt8.self).baseAddress
                    else {
                        return -1
                    }
                    
                    return Int(crypto_sign_verify_detached(sigPtr, msgPtr, UInt64(message.count), pkPtr))
                }
            }
        }
        
        return result == 0
    }
    
    /// Підписування повідомлення (detached) секретним ключем Ed25519
    static func signDetached(message: inout Data, secretKey: inout Data) throws -> Data {
        guard secretKey.count == Int(crypto_sign_SECRETKEYBYTES) else {
            throw SignError.invalidSecretKeyLength(secretKey.count)
        }
        
        var signature = Data(count: Int(crypto_sign_BYTES))
        let result = signature.withUnsafeMutableBytes { sigRawBuffer in
            message.withUnsafeBytes { msgRawBuffer in
                secretKey.withUnsafeBytes { skRawBuffer in
                    guard
                        let sigPtr = sigRawBuffer.bindMemory(to: UInt8.self).baseAddress,
                        let msgPtr = msgRawBuffer.bindMemory(to: UInt8.self).baseAddress,
                        let skPtr = skRawBuffer.bindMemory(to: UInt8.self).baseAddress
                    else {
                        return -1
                    }
                    return Int(crypto_sign_detached(sigPtr, nil, msgPtr, UInt64(message.count), skPtr))
                }
            }
        }
        
        guard result == 0 else {
            throw SignError.signingFailed(result)
        }
        
        return signature
    }
    
    static func generateKeyPair() throws -> (privateKey: Data, publicKey: Data) {
        var pk = [UInt8](repeating: 0, count: Int(crypto_sign_PUBLICKEYBYTES))
        var sk = [UInt8](repeating: 0, count: Int(crypto_sign_SECRETKEYBYTES))
        
        let result = crypto_sign_ed25519_keypair(&pk, &sk)
        guard result == 0 else {
            throw KeyGenerationError.generationFailed(Int(result))
        }
        
        return (Data(sk), Data(pk))
    }
    
    enum VerifyError: Error {
        case invalidSignatureLength(Int)
        case invalidPublicKeyLength(Int)
    }
    
    enum SignError: Error {
        case invalidSecretKeyLength(Int)
        case signingFailed(Int)
    }
    
    enum KeyGenerationError: Error {
        case generationFailed(Int)
    }
}
