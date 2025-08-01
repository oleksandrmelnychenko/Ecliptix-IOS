//
//  SignInViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.06.2025.
//

import Foundation
import SwiftUI

@MainActor
final class SignInViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showPasswordValidationErrors: Bool = true
    @Published var showPhoneNumberErrors: Bool = false
    
    @Published var shouldNavigateToMainApp: Bool = false
    @Published var shouldNavigateToRecoveryPassword: Bool = false
    
    private let secureKeyBuffer: SecureTextBuffer = .init()
    private var hasSecureKeyBeenTouched: Bool = false
    
    private let networkController: NetworkProvider
    private let phoneValidator = PhoneValidator()
    private let passwordValidator = PasswordValidator()
        
    private let authService: OpaqueAuthenticationService
    
    var phoneValidationErrors: [PhoneValidationError] {
        phoneValidator.validate(phoneNumber).errors
    }
    
    @Published private(set) var passwordValidationErrors: [PasswordValidationError] = []
    
    private func updatePasswordValidation() {
        do {
            try secureKeyBuffer.withSecureBytes { bytes in
                let password = String(data: bytes, encoding: .utf8) ?? ""
                passwordValidationErrors = passwordValidator.validate(password).errors
            }
        } catch {
            passwordValidationErrors = []
        }
    }
    
    var isFormValid: Bool {
        passwordValidationErrors.isEmpty &&
        phoneValidationErrors.isEmpty &&
        !phoneNumber.isEmpty &&
        secureKeyBuffer.length > 0
    }
    
    init() {
        self.networkController = try! ServiceLocator.shared.resolve(NetworkProvider.self)
        
        authService = OpaqueAuthenticationService(networkProvider: self.networkController)
    }
    
    func signInButton() async {
        guard isFormValid else { return }

        errorMessage = nil
        isLoading = true
        
        await self.submitSignInAsync()
        
        isLoading = false
    }
    
    func forgotPasswordTapped() {
        self.shouldNavigateToRecoveryPassword = true
    }
    
    public func insertSecureKeyChars(indext: Int, chars: String) {
        do {
            try self.secureKeyBuffer.insert(index: indext, text: chars)
            updatePasswordValidation()
        }
        catch {
            //TODO: handle exceptions here
        }
    }
    
    public func removeSecureKeyChars(index: Int, count: Int) {
        do {
            try self.secureKeyBuffer.remove(index: index, count: count)
            updatePasswordValidation()
        }
        catch {
            //TODO: handle exceptions here
        }
    }
    
    private func submitSignInAsync() async {
        await self.authService.signInAsync(
            mobileNumber: phoneNumber,
            securePassword: secureKeyBuffer)
        .Match(
            onSuccess: { sessionKey in
                //TODO: here we need to save SessionKey
                
                self.shouldNavigateToMainApp = true
                
                self.secureKeyBuffer.dispose()
        }, onFailure: { error in
            self.errorMessage = error.message
        })
    }
}
