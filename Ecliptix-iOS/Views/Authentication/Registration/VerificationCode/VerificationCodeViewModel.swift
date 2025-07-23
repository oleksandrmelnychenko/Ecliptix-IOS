//
//  VerificationCodeViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import Foundation
import GRPC

@MainActor
final class VerificationCodeViewModel: ObservableObject {
    public static let emptySign = "\u{200B}"
    public static let otpLength: Int = 6
    
    @Published var codeDigits: [String] = Array(repeating: emptySign, count: otpLength)
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var secondsRemaining: Int = 0
    @Published var remainingTime: String = "00:00"
    
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    private let phoneNumber: String
    public let navigation: NavigationService

    private let networkController: NetworkProvider
    private var phoneNumberIdentifier: Data
    private var verificationSessionIdentifier: UUID? = nil
    
    private let authFlow: AuthFlow
    
    init(phoneNumber: String, phoneNumberIdentifier: Data, navigation: NavigationService, authFlow: AuthFlow) {
        self.phoneNumber = phoneNumber
        self.navigation = navigation
        
        self.phoneNumberIdentifier = phoneNumberIdentifier
        
        self.networkController = ServiceLocator.shared.resolve(NetworkProvider.self)
        
        self.authFlow = authFlow
    }
    
    func startValidation() {
        Task {
            await self.initiateVerification(
                phoneNumberIdentifier: self.phoneNumberIdentifier,
                type: .sendOtp)
        }
    }

    var combinedCode: String {
        codeDigits.joined()
    }

    func verifyCode(onFailure: @escaping () -> Void) async {
        let code = combinedCode.replacingOccurrences(of: Self.emptySign, with: "")
        
        guard code.count == Self.otpLength else {
            await MainActor.run {
                self.errorMessage = Strings.VerificationCode.Errors.invalidCode
            }
            return
        }

        await sendVerificationCode()
    }
    
    func handleBackspace(at index: Int, focus: inout Int?) {
        if index > 0 {
            if codeDigits[index] == Self.emptySign {
                codeDigits[index - 1] = Self.emptySign
                focus = index - 1
            } else {
                codeDigits[index] = Self.emptySign
            }
        }
    }

    func handleInput(_ newValue: String, at index: Int, focus: inout Int?) {
        guard newValue != Self.emptySign else { return }

        codeDigits[index] = newValue
        if index < codeDigits.count - 1 {
            focus = index + 1
        } else {
            focus = nil
        }
    }
    
    private func initiateVerification(phoneNumberIdentifier: Data, type: Ecliptix_Proto_Membership_InitiateVerificationRequest.TypeEnum) async {
        let cancellationToken = CancellationToken()

        guard let systemDeviceIdentifier = ViewModelBase.systemDeviceIdentifier() else {
            errorMessage = "Invalid device ID"
            return
        }
        
        guard let uuid = UUID(uuidString: systemDeviceIdentifier) else {
            errorMessage = "Invalid UUID format"
            return
        }

        let deviceIdData = withUnsafeBytes(of: uuid.uuid) { Data($0) }

        var request = Ecliptix_Proto_Membership_InitiateVerificationRequest()
        request.phoneNumberIdentifier = phoneNumberIdentifier
        request.appDeviceIdentifier = deviceIdData
        request.purpose = .registration
        request.type = type

        let connectId = ViewModelBase.computeConnectId(pubKeyExchangeType: .dataCenterEphemeralConnect)

        do {
            let result = try await networkController.executeServiceAction(
                connectId: connectId,
                serviceType: .initiateVerification,
                plainBuffer: try request.serializedData(),
                flowType: .receiveStream,
                onSuccessCallback: { [weak self] payload in
                    guard let self else {
                        return .failure(.unexpectedError("Self is nil"))
                    }

                    do {
                        let timerTick = try Helpers.parseFromBytes(
                            Ecliptix_Proto_Membership_VerificationCountdownUpdate.self,
                            data: payload
                        )

                        if timerTick.alreadyVerified {
                        }

                        if timerTick.status == .failed {
                        }
                        
                        if timerTick.status == .expired {
                            // redirect to Phone verification view
                        }
                        
                        if timerTick.status == .maxAttemptsReached {
                            // redirect to Phone verification view
                        }
                        
                        if timerTick.status == .notFound {
                        }
                        
                        
                        if self.verificationSessionIdentifier == nil {
                            self.verificationSessionIdentifier = try Helpers.fromDataToGuid(timerTick.sessionIdentifier)
                        }

                        await MainActor.run {
                            self.secondsRemaining = Int(timerTick.secondsRemaining)
                            self.remainingTime = Self.formatRemainingTime(timerTick.secondsRemaining)
                        }

                        return .success(.value)
                    } catch {
                        debugPrint("Error parsing verification countdown: \(error)")
                        return .failure(.unexpectedError("Failed to parse countdown", inner: error))
                    }
                },
                token: cancellationToken
            )
            
            if result.isErr {
                // hadle this
            }
        } catch {
            debugPrint("Verification execution error: \(error)")
            errorMessage = "Failed to initiate verification"
        }
    }

    private func sendVerificationCode() async {
        guard let systemDeviceIdentifier = ViewModelBase.systemDeviceIdentifier() else {
            await MainActor.run {
                self.errorMessage = "Invalid device ID"
            }
            return
        }
        
        await MainActor.run {
            self.errorMessage = nil
            self.isLoading = true
        }
        
        guard let uuid = UUID(uuidString: systemDeviceIdentifier) else {
            errorMessage = "Invalid UUID format"
            return
        }

        let deviceIdData = withUnsafeBytes(of: uuid.uuid) { Data($0) }
        
        var verifyCodeRequest = Ecliptix_Proto_Membership_VerifyCodeRequest()
        verifyCodeRequest.code = combinedCode.replacingOccurrences(of: Self.emptySign, with: "")
        verifyCodeRequest.purpose = .registration
        verifyCodeRequest.appDeviceIdentifier = deviceIdData
        
        let connectId = ViewModelBase.computeConnectId(pubKeyExchangeType: .dataCenterEphemeralConnect)
        
        do {
            _ = try await networkController.executeServiceAction(
                connectId: connectId,
                serviceType: .verifyOtp,
                plainBuffer: try verifyCodeRequest.serializedData(),
                flowType: .single,
                onSuccessCallback: { [weak self] payload in
                    guard let self = self else {
                        return .failure(.unexpectedError("Object deallocated"))
                    }
                    
                    do {
                        let verifyCodeResponse = try Helpers.parseFromBytes(Ecliptix_Proto_Membership_VerifyCodeResponse.self, data: payload)
                        
                        await MainActor.run {
                            self.isLoading = false
                            
                            if verifyCodeResponse.result == .succeeded {
                                let membership = verifyCodeResponse.membership
                                
                                self.navigation.navigate(to: .passwordSetup(
                                    verificationSessionId: membership.uniqueIdentifier,
                                    authFlow: self.authFlow))
                            } else if verifyCodeResponse.result == .invalidOtp {
                                
                            }
                        }
                        
                        return .success(.value)
                    } catch {
                        await MainActor.run {
                            self.isLoading = false
                            self.errorMessage = "Failed to parse server response"
                        }
                        return .failure(.unexpectedError("Deserialization failed", inner: error))
                    }
                }
            )
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Network error: \(error.localizedDescription)"
            }
        }
    }
    
    func reSendVerificationCode() async {
        codeDigits = Array(repeating: Self.emptySign, count: Self.otpLength)
                
        _ = await self.initiateVerification(
            phoneNumberIdentifier: self.phoneNumberIdentifier,
            type: .resendOtp
        )
    }
    
    private static func formatRemainingTime(_ seconds: UInt64) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
