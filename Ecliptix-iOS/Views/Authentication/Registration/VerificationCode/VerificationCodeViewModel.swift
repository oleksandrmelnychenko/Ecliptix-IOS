//
//  VerificationCodeViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import Foundation
import GRPC
import SwiftUI

@MainActor
final class VerificationCodeViewModel: ObservableObject {
    public static let emptySign = "\u{200B}"
    public static let otpLength: Int = 6
    
    @Published var codeDigits: [String] = Array(repeating: emptySign, count: otpLength)
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var secondsRemaining: Int = 0
    @Published var remainingTime: String = "00:00"
    @Published var showCodeError: Bool = false
    
    @Published var showAlert: Bool = false
    @Published var alertTitle: String?
    @Published var alertMessage: String?
    
    @Published var shouldNavigateToPasswordSetUp: Bool = false
    @Published var authFlow: AuthFlow


    private let networkController: NetworkProvider
    private var phoneNumberIdentifier: Data
    private var verificationSessionIdentifier: UUID? = nil
    
    init(phoneNumberIdentifier: Data, authFlow: AuthFlow) {
        self.phoneNumberIdentifier = phoneNumberIdentifier
        
        self.networkController = try! ServiceLocator.shared.resolve(NetworkProvider.self)
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
        
        isLoading = false
        errorMessage = nil

        await sendVerificationCode(code: code)
        
        isLoading = false
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
    
    private func initiateVerification(
        phoneNumberIdentifier: Data,
        type: Ecliptix_Proto_Membership_InitiateVerificationRequest.TypeEnum
    ) async {
        let cancellationToken = CancellationToken()

        let stream = RequestPipeline.runStream(
            requestResult: RequestBuilder.buildInitiateVerificationRequest(
                networkProvider: networkController,
                phoneNumberIdentifier: phoneNumberIdentifier,
                type: type
            ),
            pubKeyExchangeType: .dataCenterEphemeralConnect,
            serviceType: .initiateVerification,
            cancellationToken: cancellationToken,
            networkProvider: networkController,
            parseAndValidate: { (response: Ecliptix_Proto_Membership_VerificationCountdownUpdate) in
                .success(response)
            }
        )

        for await result in stream {
            await result.MatchAsync(
                onSuccessAsync: { response in
                    if response.alreadyVerified {
                        // обробка
                    }

                    switch response.status {
                    case .failed, .expired, .maxAttemptsReached:
                        self.showAlert = true
                        self.alertTitle = "Warning"
                        self.alertMessage = response.message
                        
                        break
                    case .notFound:
                        
                        break
                    default:
                        break
                    }

                    if self.verificationSessionIdentifier == nil {
                        self.verificationSessionIdentifier = try? Helpers.fromDataToGuid(response.sessionIdentifier)
                    }

                    await MainActor.run {
                        self.secondsRemaining = Int(response.secondsRemaining)
                        self.remainingTime = Self.formatRemainingTime(response.secondsRemaining)
                    }
                },
                onFailureAsync: { error in
                    await MainActor.run {
                        self.errorMessage = error.message
                        self.showCodeError = true
                    }
                })
        }
    }

    private func sendVerificationCode(code: String) async {
        _ = await RequestPipeline.run(
            requestResult: RequestBuilder.buildSendOtpRequest(
                networkProvider: networkController,
                otpCode: code
            ),
            pubKeyExchangeType: .dataCenterEphemeralConnect,
            serviceType: .verifyOtp,
            flowType: .single,
            cancellationToken: CancellationToken(),
            networkProvider: networkController,
            parseAndValidate: { (response: Ecliptix_Proto_Membership_VerifyCodeResponse) in
                guard response.result != .invalidOtp else {
                    return .failure(.networkError(response.message))
                }
                                
                return .success(response)
            }
        )
        .Match(
            onSuccess: { response in
                let setUniqueIdResult = AppSettingsService.shared.setMembership(response.membership)
                
                if setUniqueIdResult.isErr {
                    self.errorMessage = "Failed to save membership"
                    self.showCodeError = true
                    return
                }
                
                self.shouldNavigateToPasswordSetUp = true
        }, onFailure: { error in
            self.errorMessage = error.message
            self.showCodeError = true
        })
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
