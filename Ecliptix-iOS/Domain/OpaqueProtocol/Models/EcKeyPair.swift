//
//  EcKeyPair.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.07.2025.
//

import OpenSSL

struct EcKeyPair {
    let privateKey: UnsafeMutablePointer<BIGNUM>
    let publicKey: OpaquePointer

    func free() {
        BN_free(privateKey)
        EC_POINT_free(publicKey)
    }
}
