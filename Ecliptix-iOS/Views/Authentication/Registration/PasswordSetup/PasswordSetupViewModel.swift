//
//  PasswordSetupViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import Foundation
import SwiftUI

@MainActor
final class PasswordSetupViewModel: ObservableObject {
    @EnvironmentObject private var navigation: NavigationService
    @EnvironmentObject private var localization: LocalizationService
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showPasswordValidationErrors: Bool = false
    @Published var showConfirmationPasswordValidationErrors: Bool = true
    @Published private(set) var passwordValidationErrors: [PasswordValidationError] = []
    @Published private(set) var confirmPasswordValidationErrors: [PasswordValidationError] = []
    @Published var shouldNavigateToPassPhase: Bool = false
    @Published private(set) var passwordStrength: PasswordStrengthType = .invalid
    
    private let passwordValidator = PasswordValidator()
    private let networkController: NetworkProvider
    private var passwordManager: PasswordManager?
    private let secureKeyBuffer: SecureTextBuffer = .init()
    private let confirmSecureKeyBuffer: SecureTextBuffer = .init()
    
    private lazy var authService: OpaqueRegistrationService = {
        return OpaqueRegistrationService(
            networkProvider: self.networkController,
            passwordManager: self.passwordManager!,
            authFlow: self.authFlow
        )
    }()
        
    private let authFlow: AuthFlow

    var isFormValid: Bool {
        passwordValidationErrors.isEmpty &&
        confirmPasswordValidationErrors.isEmpty &&
        secureKeyBuffer.length > 0 &&
        confirmSecureKeyBuffer.length > 0
    }
    
    init(authFlow: AuthFlow) {
        self.authFlow = authFlow
        
        networkController = try! ServiceLocator.shared.resolve(NetworkProvider.self)
    }
    
    public func insertSecureKeyChars(indext: Int, chars: String) {
        do {
            try self.secureKeyBuffer.insert(index: indext, text: chars)
            if !showPasswordValidationErrors {
                showPasswordValidationErrors = true
            }
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
    
    public func insertConfirmSecureKeyChars(indext: Int, chars: String) {
        do {
            try self.confirmSecureKeyBuffer.insert(index: indext, text: chars)
            updatePasswordValidation()
        }
        catch {
            //TODO: handle exceptions here
        }
    }
    
    public func removeConfirmSecureKeyChars(index: Int, count: Int) {
        do {
            try self.confirmSecureKeyBuffer.remove(index: index, count: count)
            updatePasswordValidation()
        }
        catch {
            //TODO: handle exceptions here
        }
    }
    
    private func updatePasswordValidation() {
        var password: String = ""
        var confirmPassword: String = ""
        
        do {
            try secureKeyBuffer.withSecureBytes { bytes in
                password = String(data: bytes, encoding: .utf8) ?? ""
                let passwordValidations = passwordValidator.validate(password)
                self.passwordValidationErrors = passwordValidations.errors + passwordValidations.suggestions
                passwordStrength = PasswordStrengthEstimator.estimate(password: password)
            }
        } catch {
            passwordValidationErrors = []
            passwordStrength = .invalid
            self.errorMessage = "Error during reading password"
            return
        }
        
        do {
            self.passwordManager = self.passwordManager == nil
                ? try PasswordManager.create().unwrap()
                : self.passwordManager!
        }
        catch {
            // Log this error
            errorMessage = "Failed to create password manager."
            return
        }
        /*self.passwordManager!.checkPasswordCompliance(password, policy: PasswordPolicy.standard)*/
        _ = Result<[PasswordValidationError], EcliptixProtocolFailure>.success([])
            .flatMap { validationErrors in
                if !validationErrors.isEmpty {
                    passwordValidationErrors = validationErrors
                    
                    return .success(Unit.value)
                }
                else {
                    if self.confirmSecureKeyBuffer.length == 0 {
                        self.confirmPasswordValidationErrors = [.required]
                        return .success(Unit.value)
                    }
                    
                    do {
                        try confirmSecureKeyBuffer.withSecureBytes { bytes in
                            confirmPassword = String(data: bytes, encoding: .utf8) ?? ""
                        }
                    } catch {
                        passwordValidationErrors = []
                        self.errorMessage = "Error during reading password"
                        return .success(Unit.value)
                    }
                    
                    if password != confirmPassword {
                        confirmPasswordValidationErrors = [.mismatchPasswords]
                        return .success(Unit.value)
                    } else {
                        confirmPasswordValidationErrors = []
                        return .success(Unit.value)
                    }
                }
            }
            .mapError { error in
                self.errorMessage = error.message
                return error
            }
    }

    func submitPassword() async {
        guard isFormValid else { return }

        errorMessage = nil
        isLoading = true
            
        await self.submitRegistrationPassword()
        
        isLoading = false
    }
    
    private func submitRegistrationPassword() async {
        await self.authService.signUpAsync(securePassword: secureKeyBuffer)
            .Match(
                onSuccess: { sessionKey in
                    //TODO: here we need to save SessionKey
                    
                    self.shouldNavigateToPassPhase = true
                    
                    self.secureKeyBuffer.dispose()
            }, onFailure: { error in
                self.errorMessage = error.message
            })
    }
}
