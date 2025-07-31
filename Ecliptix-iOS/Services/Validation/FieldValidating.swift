//
//  FieldValidating.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

protocol FieldValidating {
    associatedtype ErrorType: ValidationError
    
    func validate(_ value: String) -> (errors: [ErrorType], suggestions: [PasswordValidationError])
}
