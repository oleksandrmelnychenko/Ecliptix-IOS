//
//  ValidationError.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

protocol ValidationError: Identifiable, Hashable {
    var message: String { get }
}

extension ValidationError {
    var id: String { message }
}
