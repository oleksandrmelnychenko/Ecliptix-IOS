//
//  ValidationError.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

protocol ValidationError: RawRepresentable, Identifiable, Hashable where RawValue == String {}

extension ValidationError {
    var id: String { rawValue }
}
