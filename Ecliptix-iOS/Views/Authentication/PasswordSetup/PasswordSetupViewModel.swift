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
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let navigation: NavigationService
    private let passwordValidator = PasswordValidator()
    
    private var securePasswordHandle: SodiumSecureMemoryHandle?
    private var secureConfirmPasswordHandle: SodiumSecureMemoryHandle?
    private var passwordManager: PasswordManager?
    
    init(navigation: NavigationService) {
        self.navigation = navigation
    }

    var isPasswordValid: Bool {
        passwordValidator.validate(password).isEmpty
    }

    var validationErrors: [PasswordValidationError] {
        passwordValidator.validate(password)
    }

    var confirmPasswordValidationError: [PasswordValidationError] {
        passwordValidator.validateMatch(password, confirmPassword)
    }

    var isFormValid: Bool {
        isPasswordValid && confirmPasswordValidationError.isEmpty
    }

    func submitPassword() {
        guard !password.isEmpty else { return }
        guard !confirmPassword.isEmpty else { return }
        
        errorMessage = nil
        isLoading = true
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                self.isLoading = false
                
                if password == "Admin123" {
                    navigation.navigate(to: .passPhaseRegistration)
                } else {
                    self.errorMessage = Strings.PasswordSetup.Errors.invalidPassword
                }
            }
        }
    }
    
    public func updatePassword(passwordText: String?) {
        securePasswordHandle?.dispose()
        securePasswordHandle = nil
        
        do {
            if let passwordText = passwordText, !passwordText.isEmpty {
                let result = Self.convertStringToSodiumHandle(text: passwordText)
                
                if result.isOk {
                    self.securePasswordHandle = try result.unwrap()
                } else {
                    self.securePasswordHandle = nil
                    self.errorMessage = "Error processing password: \(try result.unwrapErr().message)"
                }
            }
            
            validatePasswords()
        } catch {
            
        }
    }
    
    public func updateConfirmPassword(passwordText: String?) {
        secureConfirmPasswordHandle?.dispose()
        secureConfirmPasswordHandle = nil
        
        do {
            if let passwordText = passwordText, !passwordText.isEmpty {
                let result = Self.convertStringToSodiumHandle(text: passwordText)
                
                if result.isOk {
                    self.secureConfirmPasswordHandle = try result.unwrap()
                } else {
                    self.secureConfirmPasswordHandle = nil
                    self.errorMessage = "Error processing password: \(try result.unwrapErr().message)"
                }
            }
            
            validatePasswords()
        } catch {
            
        }
    }
    
    private static func convertStringToSodiumHandle(text: String) -> Result<SodiumSecureMemoryHandle, EcliptixProtocolFailure> {
        guard text.isEmpty == false else {
            return SodiumSecureMemoryHandle.allocate(length: 0).mapSodiumFailure()
        }
        
        var rentedBuffer: Data?
        var newHandle: SodiumSecureMemoryHandle?
        
        defer {
            if rentedBuffer != nil {
                rentedBuffer!.resetBytes(in: 0..<rentedBuffer!.count)
                rentedBuffer!.removeAll()
            }
        }
        
        do {
            guard let utf8Data = text.data(using: .utf8) else {
                return .failure(.decode("Failed to encode password string to UTF-8 bytes."))
            }
            
            rentedBuffer = utf8Data
            
            let allocateResult = SodiumSecureMemoryHandle.allocate(length: utf8Data.count)
            guard allocateResult.isOk else {
                return allocateResult.mapSodiumFailure()
            }

            newHandle = try allocateResult.unwrap()
            
            let writeResult = rentedBuffer!.withUnsafeBytes { bufferPointer in
                newHandle!.write(data: bufferPointer).mapSodiumFailure()
            }
            guard writeResult.isOk else {
                newHandle?.dispose()
                return .failure(try writeResult.unwrapErr())
            }
            
            return .success(newHandle!)
        } catch {
            newHandle?.dispose()
            return .failure(.generic("Failed to convert string to secure handle.", inner: error))
        }
        
    }
    
    private func validatePasswords() {
        self.errorMessage = nil
        
        var isPasswordEntered = self.securePasswordHandle != nil && !self.securePasswordHandle!.isInvalid && self.securePasswordHandle!.length > 0
        var isConfirmPasswordEntered = self.secureConfirmPasswordHandle != nil && !self.secureConfirmPasswordHandle!.isInvalid && self.secureConfirmPasswordHandle!.length > 0
        
        if !isPasswordEntered {
            if isConfirmPasswordEntered {
                errorMessage = "Please enter your password in the first field."
            }
            
            return
        }
        
        var rentedPasswordData: Data?
        
        defer {
            if rentedPasswordData != nil {
                rentedPasswordData!.resetBytes(in: 0..<rentedPasswordData!.count)
                rentedPasswordData!.removeAll()
            }
        }
        
        do {
            rentedPasswordData = Data(count: self.securePasswordHandle!.length)
            var passwordSpan = rentedPasswordData!
            
            let readResult = passwordSpan.withUnsafeMutableBytes { destPtr in
                self.securePasswordHandle!.read(into: destPtr).mapSodiumFailure()
            }
            guard readResult.isOk else {
                self.errorMessage = "Error processing password: \(try readResult.unwrapErr().message)"
                return
            }
            
            guard let passwordString = String(data: passwordSpan, encoding: .utf8) else {
                errorMessage = "Password contains invalid characters for string conversion."
                return
            }
            
            if passwordManager == nil {
                passwordManager = try PasswordManager.create().unwrap()
            }
            
            let complianceResult = passwordManager!.checkPasswordCompliance(passwordString, policy: PasswordPolicy.standard)
            
            passwordSpan.removeAll()
            
            rentedPasswordData = nil
            
            guard complianceResult.isOk else {
                errorMessage = try complianceResult.unwrapErr().message
                return
            }
            
            if !isConfirmPasswordEntered {
                errorMessage = "Please confirm your password."
                return
            }
            
            let comparisonResult = Self.compareSodiumHandle(self.securePasswordHandle!, self.secureConfirmPasswordHandle!)
            
            guard comparisonResult.isOk else {
                errorMessage = "Error comparing passwords: \(try comparisonResult.unwrapErr().message)"
                return
            }
            
            if try !comparisonResult.unwrap() {
                errorMessage = "Passwords do not match."
                return
            }
            
            errorMessage = nil
            
        } catch {
            errorMessage = "An unexpected error occurred during validation: \(error)"
        }
    }
    
    private static func compareSodiumHandle(_ handle1: SodiumSecureMemoryHandle, _ handle2: SodiumSecureMemoryHandle) -> Result<Bool, EcliptixProtocolFailure> {
        if handle1.isInvalid || handle2.isInvalid {
            return .failure(.objectDisposed("Password handles are invalid for comparison."))
        }
        
        if handle1.length != handle2.length {
            return .success(false)
        }
        
        if handle1.length == 0 {
            return .success(true)
        }
        
        var rentedBytes1: Data?
        var rentedBytes2: Data?
        
        defer {
            if rentedBytes1 != nil {
                rentedBytes1!.resetBytes(in: 0..<rentedBytes1!.count)
                rentedBytes1!.removeAll()
            }
            if rentedBytes2 != nil {
                rentedBytes2!.resetBytes(in: 0..<rentedBytes2!.count)
                rentedBytes2!.removeAll()
            }
        }
        
        do {
            rentedBytes1 = Data(count: handle1.length)
            var span1 = rentedBytes1
            let read1Result = span1!.withUnsafeMutableBytes { destPtr in
                handle1.read(into: destPtr).mapSodiumFailure()
            }
            if read1Result.isErr {
                return .failure(try read1Result.unwrapErr())
            }
            
            rentedBytes2 = Data(count: handle2.length)
            var span2 = rentedBytes2
            let read2Result = span2!.withUnsafeMutableBytes { destPtr in
                handle2.read(into: destPtr).mapSodiumFailure()
            }
            if read2Result.isErr {
                return .failure(try read2Result.unwrapErr())
            }
            
            let areEqual = compareFixedTime(span1!, span2!)
            return .success(areEqual)
        } catch {
            return .failure(.generic("Failed to allocate memory for comparing password handles.", inner: error))
        }
    }
    
    private static func compareFixedTime(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }

        let areEqual = lhs.withUnsafeBytes { (lhsRaw: UnsafeRawBufferPointer) in
            rhs.withUnsafeBytes { (rhsRaw: UnsafeRawBufferPointer) in
                var diff: UInt8 = 0
                for i in 0..<lhs.count {
                    diff |= lhsRaw[i] ^ rhsRaw[i]
                }
                return diff == 0
            }
        }

        return areEqual
    }
}
