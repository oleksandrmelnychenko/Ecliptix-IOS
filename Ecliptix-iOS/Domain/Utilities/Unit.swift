//
//  Unit.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 22.05.2025.
//

import Foundation

struct Unit: Equatable, Hashable, CustomStringConvertible {
    static let value = Unit()

    static func == (lhs: Unit, rhs: Unit) -> Bool {
        return true
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(0)
    }

    var description: String {
        return "()"
    }
}
