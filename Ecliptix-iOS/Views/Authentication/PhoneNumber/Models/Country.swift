//
//  Country.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 21.05.2025.
//


import SwiftUI

struct Country: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let phoneCode: String
    let flag: String
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case phoneCode = "PhoneCode"
        case flag = "Flag"
    }
    
    init(id: UUID = UUID(), name: String, phoneCode: String, flag: String) {
        self.id = id
        self.name = name
        self.phoneCode = phoneCode
        self.flag = flag
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.phoneCode = try container.decode(String.self, forKey: .phoneCode)
        self.flag = try container.decode(String.self, forKey: .flag)
        self.id = UUID()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(phoneCode, forKey: .phoneCode)
        try container.encode(flag, forKey: .flag)
    }
}
