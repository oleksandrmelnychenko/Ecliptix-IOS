//
//  ExpiringKeyValue.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 03.07.2025.
//

import Foundation

struct ExpiringKeyValue: Codable {
    let data: Data
    let expirationDate: Date
}
