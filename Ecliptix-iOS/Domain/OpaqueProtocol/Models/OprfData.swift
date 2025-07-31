//
//  OprfData.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 31.07.2025.
//

import Foundation
import OpenSSL

struct OprfData {
    let oprfRequest: Data
    let blind: UnsafeMutablePointer<BIGNUM>
    
    func free() {
        BN_free(blind)
    }
}
