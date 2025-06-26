//
//  PublicKeyBundle.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 26.05.2025.
//

import Foundation
import SwiftProtobuf

class OneTimePreKeyRecord {
    var preKeyId: UInt32
    var publicKey: Data

    private init(preKeyId: UInt32, publicKey: Data) {
        self.preKeyId = preKeyId
        self.publicKey = publicKey
    }
    
    static func create(preKeyId: UInt32, publicKey: Data) -> Result<OneTimePreKeyRecord, EcliptixProtocolFailure> {
        if publicKey.count != Constants.ed25519KeySize {
            return .failure(.decode("One-time prekey public key must be \(Constants.ed25519KeySize) bytes.")
            )
        }
        return .success(OneTimePreKeyRecord(preKeyId: preKeyId, publicKey: publicKey))
    }
}

struct InternalBundleData {
    let identityEd25519: Data
    let identityX25519: Data
    let signedPreKeyId: UInt32
    let signedPreKeyPublic: Data
    let signedPreKeySignature: Data
    let oneTimePreKeys: [OneTimePreKeyRecord]
    let ephemeralX25519: Data?

    init(
        identityEd25519: Data,
        identityX25519: Data,
        signedPreKeyId: UInt32,
        signedPreKeyPublic: Data,
        signedPreKeySignature: Data,
        oneTimePreKeys: [OneTimePreKeyRecord],
        ephemeralX25519: Data?
    ) {
        self.identityEd25519 = identityEd25519
        self.identityX25519 = identityX25519
        self.signedPreKeyId = signedPreKeyId
        self.signedPreKeyPublic = signedPreKeyPublic
        self.signedPreKeySignature = signedPreKeySignature
        self.oneTimePreKeys = oneTimePreKeys
        self.ephemeralX25519 = ephemeralX25519
    }
}


class PublicKeyBundle {
    var identityEd25519: Data
    var identityX25519: Data
    var signedPreKeyId: UInt32
    var signedPreKeyPublic: Data
    var signedPreKeySignature: Data
    var oneTimePreKeys: [OneTimePreKeyRecord]
    var ephemeralX25519: Data?
    
    init(_ data: inout InternalBundleData) {
        self.identityEd25519 = data.identityEd25519
        self.identityX25519 = data.identityX25519
        self.signedPreKeyId = data.signedPreKeyId
        self.signedPreKeyPublic = data.signedPreKeyPublic
        self.signedPreKeySignature = data.signedPreKeySignature
        self.oneTimePreKeys = data.oneTimePreKeys
        self.ephemeralX25519 = data.ephemeralX25519
    }
    
    func toProtobufExchange() -> Ecliptix_Proto_PublicKeyBundle {
        var proto = Ecliptix_Proto_PublicKeyBundle()
        proto.identityPublicKey = Data(identityEd25519)
        proto.identityX25519PublicKey = Data(identityX25519)
        proto.signedPreKeyID = signedPreKeyId
        proto.signedPreKeyPublicKey = Data(signedPreKeyPublic)
        proto.signedPreKeySignature = Data(signedPreKeySignature)

        if ephemeralX25519 != nil {
            proto.ephemeralX25519PublicKey = Data(ephemeralX25519!)
        }

        for opk in oneTimePreKeys {
            var protoOpk = Ecliptix_Proto_PublicKeyBundle.OneTimePreKey()
            protoOpk.preKeyID = opk.preKeyId
            protoOpk.publicKey = Data(opk.publicKey)
            
            proto.oneTimePreKeys.append(protoOpk)
        }

        return proto
    }
    
    static func fromProtobufExchange(_ proto: Ecliptix_Proto_PublicKeyBundle?) -> Result<PublicKeyBundle, EcliptixProtocolFailure> {
        guard var proto = proto else {
            return .failure(.invalidInput("Inpout Protobuf bundle cannot be nil."))
        }
        
        return Result<PublicKeyBundle, EcliptixProtocolFailure>.Try {
            var identityEd25519 = Data(proto.identityPublicKey)
            var identityX25519 = Data(proto.identityX25519PublicKey)
            var signedPreKeyPublic = Data(proto.signedPreKeyPublicKey)
            var signedPreKeySignature = Data(proto.signedPreKeySignature)
            
            guard identityEd25519.count == Constants.ed25519KeySize else {
                throw EcliptixProtocolFailure.decode("IdentityEd25519 key must be \(Constants.ed25519KeySize) bytes.")
            }
            guard identityX25519.count == Constants.x25519KeySize else {
                throw EcliptixProtocolFailure.decode("IdentityX25519 key must be \(Constants.x25519KeySize) bytes.")
            }
            guard signedPreKeyPublic.count == Constants.x25519KeySize else {
                throw EcliptixProtocolFailure.decode("SignedPreKeyPublic key must be \(Constants.x25519KeySize) bytes.")
            }
            guard signedPreKeySignature.count == Constants.ed25519SignatureSize else {
                throw EcliptixProtocolFailure.decode("SignedPreKeySignature must be \(Constants.ed25519SignatureSize) bytes.")
            }
            
            var ephemeralX25519 = proto.ephemeralX25519PublicKey.isEmpty ? nil : Data(proto.ephemeralX25519PublicKey)
            if ephemeralX25519 != nil && ephemeralX25519!.count != Constants.x25519KeySize {
                throw EcliptixProtocolFailure.decode("EphemeralX25519 key must be \(Constants.x25519KeySize) bytes if present.")
            }
            
            var opkRecords: [OneTimePreKeyRecord] = []
            for protoOpk in proto.oneTimePreKeys {
                var opkPublicKey = protoOpk.publicKey
                let opkResult = OneTimePreKeyRecord.create(preKeyId: protoOpk.preKeyID, publicKey: opkPublicKey)
                
                if opkResult.isErr {
                    throw EcliptixProtocolFailure.decode("Invalid OneTimePreKey (ID: \(protoOpk.preKeyID)): \(try opkResult.unwrapErr())")
                }
                
                opkRecords.append(try opkResult.unwrap())
            }
            
            var internalData = InternalBundleData(
                identityEd25519: identityEd25519,
                identityX25519: identityX25519,
                signedPreKeyId: proto.signedPreKeyID,
                signedPreKeyPublic: signedPreKeyPublic,
                signedPreKeySignature: signedPreKeySignature,
                oneTimePreKeys: opkRecords,
                ephemeralX25519: ephemeralX25519
            )
            
            let localPublicKeyBundle = PublicKeyBundle(&internalData)
            
            return localPublicKeyBundle
        }.mapError { error in
            return error
        }
    }
}
