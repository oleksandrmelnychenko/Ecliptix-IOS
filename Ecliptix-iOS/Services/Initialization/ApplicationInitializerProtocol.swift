//
//  ApplicationInitializerProtocol.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 03.07.2025.
//

protocol ApplicationInitializerProtocol {
    func initializeAsync(defaultSystemSettings: DefaultSystemSettings) async -> Bool
}
