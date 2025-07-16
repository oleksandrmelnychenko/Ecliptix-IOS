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
    
    public func toProtoState() -> Result<Ecliptix_Proto_IdentityKeysState, EcliptixProtocolFailure> {
        guard !self.disposed else {
            return .failure(.objectDisposed(String(describing: EcliptixSystemIdentityKeys.self)))
        }
        
        do {
            let edSk = try self.ed25519SecretKeyHandle.readBytes(length: Constants.ed25519SecretKeySize).unwrap()
            let idSk = try self.identityX25519SecretKeyHandle.readBytes(length: Constants.x25519PrivateKeySize).unwrap()
            let spSk = try self.signedPreKeySecretKeyHandle.readBytes(length: Constants.x25519PrivateKeySize).unwrap()
            
            var opkProtos: [Ecliptix_Proto_OneTimePreKeySecret] = self.oneTimePreKeysInternal.compactMap { opk in
                guard let opkSkBytes = try? opk.privateKeyHandle.readBytes(length: Constants.x25519PrivateKeySize).unwrap() else {
                    return nil
                }

                var proto = Ecliptix_Proto_OneTimePreKeySecret()
                proto.preKeyID = opk.preKeyId
                proto.privateKey = opkSkBytes
                proto.publicKey = opk.publicKey
                return proto
            }

            var proto = Ecliptix_Proto_IdentityKeysState()
            proto.ed25519SecretKey = edSk
            proto.identityX25519SecretKey = idSk
            proto.signedPreKeySecret = spSk
            proto.ed25519PublicKey = self.ed25519PublicKey
            proto.identityX25519PublicKey = self.identityX25519PublicKey
            proto.signedPreKeyID = self.signedPreKeyId
            proto.signedPreKeyPublic = self.signedPreKeyPublic
            proto.signedPreKeySignature = self.signedPreKeySignature
            proto.oneTimePreKeys = opkProtos
            return .success(proto)
            
        } catch {
            return .failure(.generic("Failed to export identity keys to proto state.", inner: error))
        }
    }
    
    public static func fromProtoState(proto: Ecliptix_Proto_IdentityKeysState) -> Result<EcliptixSystemIdentityKeys, EcliptixProtocolFailure> {
        var edSkHandle: SodiumSecureMemoryHandle? = nil
        var idXSkHandle: SodiumSecureMemoryHandle? = nil
        var spkSkHandle: SodiumSecureMemoryHandle? = nil
        var opks: [OneTimePreKeyLocal] = []
        
        defer {
            edSkHandle?.dispose()
            idXSkHandle?.dispose()
            spkSkHandle?.dispose()
            for opk in opks {
                opk.dispose()
            }
            opks.removeAll()
            
            edSkHandle = nil
            idXSkHandle = nil
            spkSkHandle = nil
        }
        
        do {
            let edSkData = proto.ed25519SecretKey
            edSkHandle = try SodiumSecureMemoryHandle.allocate(length: edSkData.count).unwrap()
            _ = try edSkData.withUnsafeBytes { bufferPointer in
                edSkHandle!.write(data: bufferPointer).mapSodiumFailure()
            }.unwrap()
            
            let idSkData = proto.identityX25519SecretKey
            idXSkHandle = try SodiumSecureMemoryHandle.allocate(length: idSkData.count).unwrap()
            _ = try idSkData.withUnsafeBytes { bufferPointer in
                idXSkHandle!.write(data: bufferPointer).mapSodiumFailure()
            }.unwrap()
            
            let spSkData = proto.signedPreKeySecret
            spkSkHandle = try SodiumSecureMemoryHandle.allocate(length: spSkData.count).unwrap()
            _ = try spSkData.withUnsafeBytes { bufferPointer in
                spkSkHandle!.write(data: bufferPointer).mapSodiumFailure()
            }.unwrap()
            
            var edPk = proto.ed25519PublicKey
            var idXPk = proto.identityX25519PublicKey
            var spkPk = proto.signedPreKeyPublic
            var spkSig = proto.signedPreKeySignature
            
            for opkProto in proto.oneTimePreKeys {
                let skHandle = try SodiumSecureMemoryHandle.allocate(length: opkProto.privateKey.count).unwrap()
                _ = try opkProto.privateKey.withUnsafeBytes { bufferPointer in
                    skHandle.write(data: bufferPointer).mapSodiumFailure()
                }.unwrap()
                
                let opk = OneTimePreKeyLocal.createFromParts(preKeyId: opkProto.preKeyID, privateKeyHandle: skHandle, publicKey: opkProto.publicKey)
                opks.append(opk)
            }
            
            let keys = EcliptixSystemIdentityKeys(
                edSk: edSkHandle!, edPk: &edPk,
                idSk: idXSkHandle!, idPk: &idXPk,
                spkId: proto.signedPreKeyID, spkSk: spkSkHandle!, spkPk: &spkPk, spkSig: &spkSig,
                opks: &opks)
            
            return .success(keys)
        } catch {
            return .failure(.generic("Failed to rehydrate EcliptixSystemIdentityKeys from proto", inner: error))
        }
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
            .flatMap { edKeys in
                edSkHandle = edKeys.skHandle
                edPk = edKeys.pk
                return generateX25519IdentityKeys()
            }
            .flatMap { idKeys in
                idXSkHandle = idKeys.skHandle
                idXPk = idKeys.pk
                spkId = generateRandomUInt32()
                return generateX25519SignedPreKey(id: spkId)
            }
            .flatMap { spkKeys in
                spkSkHandle = spkKeys.skHandle
                spkPk = spkKeys.pk
                return signSignedPreKey(edSkHandle: edSkHandle!, spkPk: &spkPk!)
            }
            .flatMap { signature in
                spkSig = signature
                return generateOneTimePreKeys(count: oneTimeKeyCount)
            }
            .flatMap { generatedOpks in
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

    
    public func createPublicBundle() -> Result<PublicKeyBundle, EcliptixProtocolFailure> {
        if disposed {
            return .failure(.objectDisposed(String(describing: EcliptixSystemIdentityKeys.self)))
        }
        
        return Result<PublicKeyBundle, EcliptixProtocolFailure>.Try {
            let opkRecords: [OneTimePreKeyRecord] = try self.oneTimePreKeysInternal.compactMap { opkLocal in
                let opkKeyCreateResult = OneTimePreKeyRecord.create(preKeyId: opkLocal.preKeyId, publicKey: opkLocal.publicKey)
                return opkKeyCreateResult.isOk ? try opkKeyCreateResult.unwrap() : nil
            }
            
            var internalBundle = InternalBundleData(
                identityEd25519: self.ed25519PublicKey,
                identityX25519: self.identityX25519PublicKey,
                signedPreKeyId: self.signedPreKeyId,
                signedPreKeyPublic: self.signedPreKeyPublic,
                signedPreKeySignature: self.signedPreKeySignature,
                oneTimePreKeys: opkRecords,
                ephemeralX25519: self.ephemeralX25519PublicKey)
            
            let localBundle = PublicKeyBundle(&internalBundle)
            
            return localBundle
        } errorMapper: { error in
            .generic("Failed to create public key bundle.", inner: error)
        }
    }
    
    public func generateEphemeralKeyPair() {
        if disposed {
            _ = Result<Unit, EcliptixProtocolFailure>.failure(.objectDisposed(String(describing: EcliptixSystemIdentityKeys.self)))
            return
        }

        self.ephemeralSecretKeyHandle?.dispose()
        _ = SodiumInterop.secureWipe(&self.ephemeralX25519PublicKey)

        let generationResult = SodiumInterop.generateX25519KeyPair(keyPurpose: "Ephemeral")
        
        if generationResult.isOk {
            _ = generationResult.map { keys in
                self.ephemeralSecretKeyHandle = keys.skHandle
                self.ephemeralX25519PublicKey = keys.pk
                
                return keys
            }
        } else {
            self.ephemeralSecretKeyHandle = nil
            self.ephemeralX25519PublicKey = nil
        }
        
    }

    
    public func x3dhDeriveSharedSecret(remoteBundle: PublicKeyBundle, info: Data) -> Result<SodiumSecureMemoryHandle, EcliptixProtocolFailure> {
        var ephemeralHandleUsed: SodiumSecureMemoryHandle? = nil
        var secureOutputHandle: SodiumSecureMemoryHandle? = nil
        
        var ephemeralSecretCopy: Data? = nil
        var identitySecretCopy: Data? = nil
        var dh1: Data? = nil
        var dh2: Data? = nil
        var dh3: Data? = nil
        var dh4: Data? = nil
        var ikmBytes: Data? = nil
        var dhConcatBytes: Data? = nil
        var hkdfOutput: Data? = nil
                
        defer {
            ephemeralHandleUsed?.dispose()
            secureOutputHandle?.dispose()
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
            let hkdfInfoValidationResult = Self.validateHkdfInfo(info)
            if hkdfInfoValidationResult.isErr {
                return .failure(try hkdfInfoValidationResult.unwrapErr())
            }
            
            let validationResult: Result<Unit, EcliptixProtocolFailure> = checkDisposed()
                .flatMap { _ in Self.validateRemoteBundle(remoteBundle) }
                .flatMap { _ in ensureLocalKeysValid() }
            
            if validationResult.isErr {
                return .failure(try validationResult.unwrapErr())
            }
            
            let readEphResult = self.ephemeralSecretKeyHandle!.readBytes(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
            if readEphResult.isErr {
                return .failure(try readEphResult.unwrapErr())
            }
            ephemeralSecretCopy = try readEphResult.unwrap()
            
            let readIdResult = self.identityX25519SecretKeyHandle.readBytes(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
            if readIdResult.isErr {
                return .failure(try readIdResult.unwrapErr())
            }
            identitySecretCopy = try readIdResult.unwrap()
            ephemeralHandleUsed = self.ephemeralSecretKeyHandle
            self.ephemeralSecretKeyHandle = nil
            
            let remoteOpk = remoteBundle.oneTimePreKeys.first
            let useOpk = remoteOpk?.publicKey.count == Constants.x25519PublicKeySize

            dh1 = try ScalarMult.mult(ephemeralSecretCopy!, remoteBundle.identityX25519)
            dh2 = try ScalarMult.mult(ephemeralSecretCopy!, remoteBundle.signedPreKeyPublic)
            dh3 = try ScalarMult.mult(identitySecretCopy!, remoteBundle.signedPreKeyPublic)
            if useOpk {
                dh4 = try ScalarMult.mult(ephemeralSecretCopy!, remoteOpk!.publicKey)
            }
            
            dhConcatBytes = Data()
            Self.concatenateDhResults(destination: &dhConcatBytes!, dh1: dh1!, dh2: dh2!, dh3: dh3!, dh4: dh4)
            
            let f32 = Data(repeating: 0xFF, count: Constants.x25519KeySize)
            ikmBytes = f32 + dhConcatBytes!
            hkdfOutput = Data(count: Constants.x25519KeySize)
            
            var hkdfSaltSpan: Data? = nil
            let hkdf = try HkdfSha256(ikm: &ikmBytes!, salt: &hkdfSaltSpan)
            try hkdf.expand(info: info, output: &hkdfOutput!)
            
            let allocResult = SodiumSecureMemoryHandle.allocate(length: Constants.x25519KeySize).mapSodiumFailure()
            if allocResult.isErr {
                return .failure(try allocResult.unwrapErr())
            }
            secureOutputHandle = try allocResult.unwrap()
            
            let writeResult = hkdfOutput!.withUnsafeBytes { bufferPointer in
                secureOutputHandle!.write(data: bufferPointer).mapSodiumFailure()
            }
            if writeResult.isErr {
                return .failure(try writeResult.unwrapErr())
            }
            
            let returnHandle = secureOutputHandle!
            secureOutputHandle = nil
            return .success(returnHandle)
        } catch {
            return .failure(.unexpectedError("Unexpected error in \(String(describing: EcliptixSystemIdentityKeys.self)).", inner: error))
        }
    }
    
    public func calculateSharedSecretAsRecipient(remoteIdentityPublicKeyX: Data, remoteEphemeralPublicKeyX: Data, usedLocalOpkId: UInt32?, info: Data) -> Result<SodiumSecureMemoryHandle, EcliptixProtocolFailure> {
        
        var secureOutputHandle: SodiumSecureMemoryHandle? = nil
        var identitySecretCopy: Data? = nil
        var signedPreKeySecretCopy: Data? = nil
        var oneTimePreKeySecretCopy: Data? = nil
        var dh1: Data? = nil, dh2: Data? = nil, dh3: Data? = nil, dh4: Data? = nil
        var dhConcatBytes: Data? = nil, hkdfOutput: Data? = nil
        var opkSecretHandle: SodiumSecureMemoryHandle? = nil
        var ikmBytes: Data? = nil
        
        defer {
            secureOutputHandle?.dispose()
            if identitySecretCopy != nil {
                _ = SodiumInterop.secureWipe(&identitySecretCopy)
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
            if ikmBytes != nil {
                _ = SodiumInterop.secureWipe(&ikmBytes)
            }
        }
        
        do {
            let hkdfInfoValidationResult = Self.validateHkdfInfo(info)
            if hkdfInfoValidationResult.isErr {
                return .failure(try hkdfInfoValidationResult.unwrapErr())
            }
            
            let remoteRecipientKeysValidationResult = Self.validateRemoteRecipientKeys(remoteIdentityPublicKeyX: remoteIdentityPublicKeyX, remoteEphemeralPublicKeyX: remoteEphemeralPublicKeyX)
            if remoteRecipientKeysValidationResult.isErr {
                return .failure(try remoteRecipientKeysValidationResult.unwrapErr())
            }
            
            let validationResult = checkDisposed()
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
            
            let readIdResult = self.identityX25519SecretKeyHandle.readBytes(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
            if readIdResult.isErr {
                return .failure(try readIdResult.unwrapErr())
            }
            identitySecretCopy = try readIdResult.unwrap()
            
            let readSpkResult = self.signedPreKeySecretKeyHandle.readBytes(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
            if readSpkResult.isErr {
                return .failure(try readSpkResult.unwrapErr())
            }
            signedPreKeySecretCopy = try readSpkResult.unwrap()
            
            if opkSecretHandle != nil {
                let readOpkResult = opkSecretHandle!.readBytes(length: Constants.x25519PrivateKeySize).mapSodiumFailure()
                if readOpkResult.isErr {
                    return .failure(try readOpkResult.unwrapErr())
                }
                oneTimePreKeySecretCopy = try readOpkResult.unwrap()
            }
            
            dh1 = try ScalarMult.mult(identitySecretCopy!, remoteEphemeralPublicKeyX)
            dh2 = try ScalarMult.mult(signedPreKeySecretCopy!, remoteEphemeralPublicKeyX)
            dh3 = try ScalarMult.mult(signedPreKeySecretCopy!, remoteIdentityPublicKeyX)
            if oneTimePreKeySecretCopy != nil {
                dh4 = try ScalarMult.mult(oneTimePreKeySecretCopy!, remoteEphemeralPublicKeyX)
            }

            dhConcatBytes = Data()
            Self.concatenateDhResults(destination: &dhConcatBytes!, dh1: dh1!, dh2: dh2!, dh3: dh3!, dh4: dh4)
            
            let f32 = Data(repeating: 0xFF, count: Constants.x25519KeySize)
            ikmBytes = f32 + dhConcatBytes!
            hkdfOutput = Data(capacity: Constants.x25519KeySize)
            
            var hkdfSaltSpan: Data? = nil
            let hkdf = try HkdfSha256(ikm: &ikmBytes!, salt: &hkdfSaltSpan)
            try hkdf.expand(info: info, output: &hkdfOutput!)
            
            let allocResult = SodiumSecureMemoryHandle.allocate(length: Constants.x25519KeySize).mapSodiumFailure()
            if allocResult.isErr {
                return .failure(try allocResult.unwrapErr())
            }
            
            secureOutputHandle = try allocResult.unwrap()
            let writeResult = hkdfOutput!.withUnsafeBytes { bufferPointer in
                secureOutputHandle!.write(data: bufferPointer).mapSodiumFailure()
            }
            if writeResult.isErr {
                return .failure(try writeResult.unwrapErr())
            }
            let returnHandle = secureOutputHandle!
            secureOutputHandle = nil
            return .success(returnHandle)
        } catch {
            return .failure(.deriveKey("Unhandled error during shared secret calculation (Bob).", inner: error))
        }
    }
    
    static func generateEd25519Keys() -> Result<(skHandle: SodiumSecureMemoryHandle, pk: Data), EcliptixProtocolFailure> {
        var skHandle: SodiumSecureMemoryHandle? = nil
        var skBytes: Data? = nil
        
        defer {
            if skBytes != nil {
                _ = SodiumInterop.secureWipe(&skBytes)
            }
        }
        
        return Result<(skHandle: SodiumSecureMemoryHandle, pk: Data), EcliptixProtocolFailure>.Try {
            let edKeyPair = try PublicKeyAuth.generateKeyPair()
            skBytes = edKeyPair.privateKey
            let pkBytes = edKeyPair.publicKey
            
            skHandle = try SodiumSecureMemoryHandle.allocate(length: Constants.ed25519SecretKeySize).unwrap()
            _ = try skBytes!.withUnsafeBytes { bufferPointer in
                try skHandle!.write(data: bufferPointer).unwrap()
            }

            return (skHandle: skHandle!, pk: pkBytes)
        } errorMapper: { ex in
            EcliptixProtocolFailure.keyGeneration("Failed to generate Ed25519 key pair.", inner: ex)
        }
    }

    static func generateX25519IdentityKeys() -> Result<(skHandle: SodiumSecureMemoryHandle, pk: Data), EcliptixProtocolFailure> {
        SodiumInterop.generateX25519KeyPair(keyPurpose: "Identity")
    }

    static func generateX25519SignedPreKey(id: UInt32) -> Result<(skHandle: SodiumSecureMemoryHandle, pk: Data), EcliptixProtocolFailure> {
        SodiumInterop.generateX25519KeyPair(keyPurpose: "Signed PreKey (ID: \(id))")
    }
    
    static func signSignedPreKey(edSkHandle: SodiumSecureMemoryHandle, spkPk: inout Data) -> Result<Data, EcliptixProtocolFailure> {
        var tempEdSignKeyCopy: Data?
        
        defer {
            if tempEdSignKeyCopy != nil {
                _ = SodiumInterop.secureWipe(&tempEdSignKeyCopy)
            }
        }
        
        do {
            let readResult = edSkHandle.readBytes(length: Constants.ed25519SecretKeySize).mapSodiumFailure()
            if readResult.isErr {
                return .failure(try readResult.unwrapErr())
            }
            tempEdSignKeyCopy = try readResult.unwrap()
            
            let signResult = Result<Data, EcliptixProtocolFailure>.Try {
                try PublicKeyAuth.signDetached(message: &spkPk, secretKey: &tempEdSignKeyCopy!)
            } errorMapper: { error in
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
            : .success(.value)
    }
    
    private static func validateHkdfInfo(_ infoCopy: Data?) -> Result<Unit, EcliptixProtocolFailure> {
        return infoCopy == nil || infoCopy!.isEmpty
        ? .failure(.deriveKey("HKDF info cannot be empty."))
        : .success(.value)
    }
    
    private static func validateRemoteBundle(_ remoteBundle: PublicKeyBundle?) -> Result<Unit, EcliptixProtocolFailure> {
        if remoteBundle == nil {
            return .failure(.invalidInput("Remote bundle cannot be null."))
        }
        if remoteBundle!.identityX25519.count != Constants.x25519PublicKeySize {
            return .failure(.peerPubKey("Invalid remote IdentityX25519 key."))
        }
        if remoteBundle!.signedPreKeyPublic.count != Constants.x25519PublicKeySize {
            return .failure(.peerPubKey("Invalid remote SignedPreKeyPublic key."))
        }
        return .success(.value)
    }

    private func ensureLocalKeysValid() -> Result<Unit, EcliptixProtocolFailure> {
        if self.ephemeralSecretKeyHandle == nil || self.ephemeralSecretKeyHandle!.isInvalid {
            return .failure(.prepareLocal("Local ephemeral key is missing or invalid."))
        }
        if self.identityX25519SecretKeyHandle.isInvalid {
            return .failure(.prepareLocal("Local identity key is missing or invalid."))
        }
        return .success(.value)
    }
    
    private static func concatenateDhResults(destination: inout Data, dh1: Data, dh2: Data, dh3: Data, dh4: Data?) {
        destination.append(dh1)
        destination.append(dh2)
        destination.append(dh3)
        if let dh4 = dh4 {
            destination.append(dh4)
        }
    }
    
    public static func verifyRemoteSpkSignature(remoteIdentityEd25519: Data, remoteSpkPublic: Data, remoteSpkSignature: Data) -> Result<Bool, EcliptixProtocolFailure> {
        
        guard remoteIdentityEd25519.count == Constants.ed25519PublicKeySize else {
            return .failure(.peerPubKey("Invalid remote Ed25519 identity key length (\(remoteIdentityEd25519.count))."))
        }
        
        guard remoteSpkPublic.count == Constants.x25519PublicKeySize else {
            return .failure(.peerPubKey("Invalid remote Signed PreKey public key length (\(remoteSpkPublic.count))."))
        }
        
        guard remoteSpkSignature.count == Constants.ed25519SignatureSize else {
            return .failure(.handshake("Invalid remote Signed PreKey signature length (\(remoteSpkSignature.count))."))
        }
        
        do {
            let verificationResult = try PublicKeyAuth.verifyDetached(signature: remoteSpkSignature, message: remoteSpkPublic, publicKey: remoteIdentityEd25519)
            return verificationResult ? .success(true) : .failure(.handshake("Remote SPK signature verification failed."))
        } catch {
            return .failure(.unexpectedError("Failed to verify remote SPK signature: \(error.localizedDescription)."))
        }
    }
    
    private static func validateRemoteRecipientKeys(remoteIdentityPublicKeyX: Data, remoteEphemeralPublicKeyX: Data) -> Result<Unit, EcliptixProtocolFailure> {
        
        guard remoteIdentityPublicKeyX.count == Constants.x25519PublicKeySize else {
            return .failure(.peerPubKey("Invalid remote Identity key length."))
        }
        
        guard remoteEphemeralPublicKeyX.count == Constants.x25519PublicKeySize else {
            return .failure(.peerPubKey("Invalid remote Ephemeral key length."))
        }
        
        return .success(.value)
    }
    
    private func ensureLocalRecipientKeysValid() -> Result<Unit, EcliptixProtocolFailure> {
        if self.identityX25519SecretKeyHandle.isInvalid {
            return .failure(.prepareLocal("Local identity key is missing or invalid."))
        }
        if self.signedPreKeySecretKeyHandle.isInvalid {
            return .failure(.prepareLocal("Local signed prekey is missing or invalid."))
        }
        return .success(.value)
    }

    private func findLocalOpkHandle(_ opkId: UInt32) -> Result<SodiumSecureMemoryHandle?, EcliptixProtocolFailure> {
        for opk in self.oneTimePreKeysInternal where opk.preKeyId == opkId {
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
    static func verifyDetached(signature: Data, message: Data, publicKey: Data) throws -> Bool {
        guard signature.count == Int(crypto_sign_BYTES) else {
            throw VerifyError.invalidSignatureLength(signature.count)
        }
        guard publicKey.count == Int(crypto_sign_PUBLICKEYBYTES) else {
            throw VerifyError.invalidPublicKeyLength(publicKey.count)
        }
        
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
