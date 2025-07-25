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
    
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showPasswordValidationErrors: Bool = false
    @Published var showConfirmationPasswordValidationErrors: Bool = false

    @Published var shouldNavigateToPassPhase: Bool = false
    
    private let passwordValidator = PasswordValidator()
    private let networkController: NetworkProvider
    private var passwordManager: PasswordManager?

    private var securePasswordHandle: SodiumSecureMemoryHandle?
    private var secureConfirmPasswordHandle: SodiumSecureMemoryHandle?
    
    private let verificationSessionId: Data
    
    private let authFlow: AuthFlow
    
    init(verficationSessionId: Data, authFlow: AuthFlow) {
        self.verificationSessionId = verficationSessionId
        self.authFlow = authFlow
        
        networkController = try! ServiceLocator.shared.resolve(NetworkProvider.self)
    }

    var passwordValidationErrors: [PasswordValidationError] {
        passwordValidator.validate(password)
    }
    
    var confirmPasswordValidationErrors: [PasswordValidationError] = []

    var isFormValid: Bool {
        passwordValidationErrors.isEmpty &&
        confirmPasswordValidationErrors.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        securePasswordHandle != nil && !securePasswordHandle!.isInvalid &&
        secureConfirmPasswordHandle != nil && !secureConfirmPasswordHandle!.isInvalid
    }

    func submitPassword() async {
        guard isFormValid else { return }

        switch self.authFlow {
        case .registration:
            await self.submitRegistrationPassword()
        case .recovery:
            await self.submitRecoveryPassword()
        }
        
    }

    func updatePassword(passwordText: String?) {
        securePasswordHandle?.dispose()
        securePasswordHandle = nil
        
        self.showPasswordValidationErrors = true

        do {
            if passwordText != nil && !passwordText!.isEmpty {
                let result = Self.convertStringToSodiumHandle(text: passwordText!)
                if result.isOk {
                    securePasswordHandle = try result.unwrap()
                } else {
                    securePasswordHandle = nil
                    errorMessage = "Error processing password: \(try result.unwrapErr())"
                }
            }

            validatePasswords()
        } catch {
            
        }
    }

    func updateConfirmPassword(passwordText: String?) {
        secureConfirmPasswordHandle?.dispose()
        secureConfirmPasswordHandle = nil
        
        self.showConfirmationPasswordValidationErrors = true

        do {
            if passwordText != nil && !passwordText!.isEmpty {
                let result = Self.convertStringToSodiumHandle(text: passwordText!)
                if result.isOk {
                    secureConfirmPasswordHandle = try result.unwrap()
                } else {
                    secureConfirmPasswordHandle = nil
                    errorMessage = "Error processing confirmation password: \(try result.unwrapErr())"
                }
            }

            validatePasswords()
        } catch {
            
        }
    }

    private func validatePasswords() {
        self.errorMessage = nil
        
        let isPasswordEntered = self.securePasswordHandle != nil && !self.securePasswordHandle!.isInvalid && self.securePasswordHandle!.length > 0
        let isConfirmPasswordEntered = self.secureConfirmPasswordHandle != nil && !self.secureConfirmPasswordHandle!.isInvalid && self.secureConfirmPasswordHandle!.length > 0
        
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
            
            let readResult = rentedPasswordData!.withUnsafeMutableBytes { destPtr in
                self.securePasswordHandle!.read(into: destPtr).mapSodiumFailure()
            }
            guard readResult.isOk else {
                self.errorMessage = "Error processing password: \(try readResult.unwrapErr().message)"
                return
            }
            
            guard let passwordString = String(data: rentedPasswordData!, encoding: .utf8) else {
                errorMessage = "Password contains invalid characters for string conversion."
                return
            }

            if self.passwordManager == nil {
                self.passwordManager = try? PasswordManager.create().unwrap()
            }

            let complianceResult = self.passwordManager!.checkPasswordCompliance(passwordString, policy: .standard)
                        
            rentedPasswordData!.removeAll()
            rentedPasswordData = nil
            
            if complianceResult.isErr {
                self.errorMessage = try complianceResult.unwrapErr().message
                return
            }
            
            if confirmPassword.isEmpty {
                return
            }
            
            let comparisonResult = Self.compareSodiumHandle(self.securePasswordHandle, self.secureConfirmPasswordHandle)
            
            guard comparisonResult.isOk else {
                errorMessage = "Error comparing passwords: \(try comparisonResult.unwrapErr().message)"
                return
            }
            
            if try !comparisonResult.unwrap() {
                confirmPasswordValidationErrors = [.mismatchPasswords]
                return
            }
            
            confirmPasswordValidationErrors = []
            errorMessage = nil
            
        } catch {
            errorMessage = "An unexpected error occurred during validation: \(error)"
        }
    }

    private static func convertStringToSodiumHandle(text: String) -> Result<SodiumSecureMemoryHandle, EcliptixProtocolFailure> {
        guard !text.isEmpty else {
            return SodiumSecureMemoryHandle.allocate(length: 0).mapSodiumFailure()
        }

        guard let utf8Data = text.data(using: .utf8) else {
            return .failure(.decode("Failed to encode password string to UTF-8 bytes."))
        }

        var rentedBuffer: Data? = utf8Data
        defer {
            rentedBuffer?.resetBytes(in: 0..<utf8Data.count)
            rentedBuffer?.removeAll()
        }

        do {
            let handle = try SodiumSecureMemoryHandle.allocate(length: utf8Data.count).unwrap()
            let writeResult = rentedBuffer!.withUnsafeBytes { ptr in
                handle.write(data: ptr).mapSodiumFailure()
            }

            guard writeResult.isOk else {
                handle.dispose()
                return .failure(try writeResult.unwrapErr())
            }

            return .success(handle)
        } catch {
            return .failure(.generic("Failed to convert string to secure handle.", inner: error))
        }
    }

    private static func compareSodiumHandle(_ handle1: SodiumSecureMemoryHandle?, _ handle2: SodiumSecureMemoryHandle?) -> Result<Bool, EcliptixProtocolFailure> {
        guard let handle1 = handle1 else {
            return .failure(.generic("Handle1 is nil."))
        }
        guard let handle2 = handle2 else {
            return .failure(.generic("Handle2 is nil."))
        }
        
        if handle1.isInvalid || handle2.isInvalid {
            return .failure(.objectDisposed("Password handles are invalid for comparison."))
        }

        guard handle1.length == handle2.length else {
            return .success(false)
        }

        do {
            let rentedBytes1 = Data(count: handle1.length)
            var span1 = rentedBytes1
            let read1Result = span1.withUnsafeMutableBytes { destPtr in
                handle1.read(into: destPtr).mapSodiumFailure()
            }
            if read1Result.isErr {
                return .failure(try read1Result.unwrapErr())
            }

            let rentedBytes2 = Data(count: handle2.length)
            var span2 = rentedBytes2
            let read2Result = span2.withUnsafeMutableBytes { destPtr in
                handle2.read(into: destPtr).mapSodiumFailure()
            }
            if read2Result.isErr {
                return .failure(try read2Result.unwrapErr())
            }

            return .success(compareFixedTime(span1, span2))
        } catch {
            return .failure(.generic("Failed to compare secure memory.", inner: error))
        }
    }

    private static func compareFixedTime(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }

        var diff: UInt8 = 0
        for i in 0..<lhs.count {
            diff |= lhs[i] ^ rhs[i]
        }

        return diff == 0
    }
    
    private func submitRegistrationPassword() async {
        guard let securePasswordHandle = self.securePasswordHandle, securePasswordHandle.length > 0 else {
            self.errorMessage = "Password is required."
            return
        }

        guard isFormValid else {
            self.errorMessage = "Submission requirements not met."
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
                
        let result = getPasswordData(securePasswordHandle: self.securePasswordHandle!)
            .flatMap { passwordData in
                OpaqueProtocolService.createOprfRequest(password: passwordData)
                    .mapError { .internalServiceApi("Failed to create OPRF request", inner: $0) }
                    .map { oprfData in (passwordData, oprfData) }
            }
        
        await result.MatchAsync(
            onSuccessAsync: { (passwordData, oprfData) in
                _ = await RequestPipeline.runAsync(
                    requestResult: RequestBuilder.buildRegistrationInitRequest(
                        passwordData: passwordData,
                        oprfRequest: oprfData.oprfRequest,
                        passwordManager: self.passwordManager!,
                        verificationSessionId: self.verificationSessionId),
                    pubKeyExchangeType: .dataCenterEphemeralConnect,
                    serviceType: .opaqueRegistrationInit,
                    flowType: .single,
                    cancellationToken: CancellationToken(),
                    networkProvider: self.networkController,
                    parseAndValidate: { (response: Ecliptix_Proto_Membership_OprfRegistrationInitResponse) in
                        guard response.result == .succeeded else {
                            return .failure(InternalValidationFailure.networkError(response.message))
                        }
                                        
                        return .success(response)
                    })
                    .MatchAsync(
                        onSuccessAsync: { response in
                            await RequestPipeline.run(
                                requestResult: RequestBuilder.buildRegistrationCompleteRequest(
                                    passwordData: passwordData,
                                    blind: oprfData.blind,
                                    response: response),
                                pubKeyExchangeType: .dataCenterEphemeralConnect,
                                serviceType: .opaqueRegistrationComplete,
                                flowType: .single,
                                cancellationToken: CancellationToken(),
                                networkProvider: self.networkController,
                                parseAndValidate: { (response: Ecliptix_Proto_Membership_OprfRegistrationCompleteResponse) in
                                    
                                    
                                    return .success(response)
                                })
                            .Match(onSuccess: { _ in
                                self.shouldNavigateToPassPhase = true
                            }, onFailure: { error in
                                self.errorMessage = error.message
                            })
                        },
                        onFailureAsync: { error in
                            self.errorMessage = error.message
                        }
                    )
        },
            onFailureAsync: { error in
                self.errorMessage = error.message
        })
        
    }
    
    
    private func submitRecoveryPassword() async {
//        if !isFormValid && securePasswordHandle!.length == 0 {
//            errorMessage = "Submission requirements not met."
//            return
//        }
//        
//        guard let securePasswordHandle = self.securePasswordHandle else {
//            errorMessage = "Failed to obtain secure password handle."
//            return
//        }
//        
//        do {
//            self.passwordManager = self.passwordManager == nil
//                ? try PasswordManager.create().unwrap()
//                : self.passwordManager!
//        }
//        catch {
//            // Log this error
//            errorMessage = "Failed to create password manager."
//            return
//        }
//                
//        _ = await RequestPipeline.runAsync(
//            requestResult: RequestBuilder.buildRecoverySecureKeyInitRequest(
//                securePasswordHandle: securePasswordHandle,
//                passwordManager: self.passwordManager!,
//                verificationSessionId: self.verificationSessionId),
//            pubKeyExchangeType: .dataCenterEphemeralConnect,
//            serviceType: .opaqueRecoverySecretKeyInitRequest,
//            flowType: .single,
//            cancellationToken: CancellationToken(),
//            networkProvider: self.networkController,
//            parseAndValidate: { (response: Ecliptix_Proto_Membership_OprfRecoverySecureKeyInitResponse) in
//                guard response.result == .succeeded else {
//                    return .failure(InternalValidationFailure.networkError(response.message))
//                }
//                                
//                return .success(response)
//            })
//            .MatchAsync(
//                onSuccessAsync: { response in
//                    await RequestPipeline.run(
//                        requestResult: RequestBuilder.buildRecoverySecureKeyCompleteRequest(
//                            securePasswordHandle: securePasswordHandle,
//                            response: response),
//                        pubKeyExchangeType: .dataCenterEphemeralConnect,
//                        serviceType: .opaqueRecoverySecretKeyCompleteRequest,
//                        flowType: .single,
//                        cancellationToken: CancellationToken(),
//                        networkProvider: self.networkController,
//                        parseAndValidate: { (response: Ecliptix_Proto_Membership_OprfRecoverySecretKeyCompleteResponse) in
//                            
//                            
//                            return .success(response)
//                        })
//                    .Match(onSuccess: { _ in
//                        self.navigation.navigate(to: .passPhaseRegistration)
//                    }, onFailure: { error in
//                        self.errorMessage = error.message
//                    })
//                },
//                onFailureAsync: { error in
//                    self.errorMessage = error.message
//                }
//            )
    }
    
    private func getPasswordData(
        securePasswordHandle: SodiumSecureMemoryHandle
    ) -> Result<Data, InternalValidationFailure> {
        var rentedPasswordBytes: Data? = Data(count: securePasswordHandle.length)

        defer {
            if var bytes = rentedPasswordBytes {
                bytes.resetBytes(in: 0..<bytes.count)
                bytes.removeAll()
                rentedPasswordBytes = nil
            }
        }
        
        return Result<Data, InternalValidationFailure>.Try({
            _ = try rentedPasswordBytes!.withUnsafeMutableBytes { destPtr in
                try securePasswordHandle
                    .read(into: destPtr)
                    .mapSodiumFailure()
                    .mapEcliptixProtocolFailure()
                    .mapNetworkFailure()
                    .unwrap()
            }
            return rentedPasswordBytes!
        }, errorMapper: { error in
            if let mapped = error as? InternalValidationFailure {
                return mapped
            } else {
                return .internalServiceApi("Failed to read password from secure memory", inner: error)
            }
        })
    }
}
