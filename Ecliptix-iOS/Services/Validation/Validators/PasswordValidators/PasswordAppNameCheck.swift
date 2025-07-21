//
//  PasswordAppNameCheck.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 21.07.2025.
//

struct PasswordAppNameCheck {
    private static let appNameVariants: [String] = ["ecliptix", "eclip", "opaque"]

    static func containsAppNameVariant(_ s: String) -> Bool {
        let lowercased = s.lowercased()
        return appNameVariants.contains { lowercased.contains($0) }
    }
}
