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
    
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    @Published var shouldNavigateToPasswordSetUp: Bool = false
    @Published var uniqueIdentifier: Data?
    @Published var authFlow: AuthFlow

    private let phoneNumber: String

    private let networkController: NetworkProvider
    private var phoneNumberIdentifier: Data
    private var verificationSessionIdentifier: UUID? = nil
    
    init(phoneNumber: String, phoneNumberIdentifier: Data, authFlow: AuthFlow) {
        self.phoneNumber = phoneNumber
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
        
        guard code.count == Self.otpLength else {
            await MainActor.run {
                self.errorMessage = "invalid code"
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
    
    private func initiateVerification(
        phoneNumberIdentifier: Data,
        type: Ecliptix_Proto_Membership_InitiateVerificationRequest.TypeEnum
    ) async {
        let cancellationToken = CancellationToken()
    
        await RequestBuilder.buildInitiateVerificationRequest(phoneNumberIdentifier: phoneNumberIdentifier, type: type)
            .prepareSerializedRequest(pubKeyExchangeType: .dataCenterEphemeralConnect)
            .flatMapAsync({ (request, connectId) in
                await self.networkController.executeServiceAction(
                    connectId: connectId,
                    serviceType: .initiateVerification,
                    plainBuffer: request,
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
                ).mapNetworkFailure()
            })
            .Match(
                onSuccess: { _ in
                    
                },
                onFailure: { error in
                    self.errorMessage = error.message
                }
            )
    }

    private func sendVerificationCode() async {        
        _ = await RequestPipeline.run(
            requestResult: RequestBuilder.buildSendOtpRequest(otpCode: combinedCode.replacingOccurrences(of: Self.emptySign, with: "")),
            pubKeyExchangeType: .dataCenterEphemeralConnect,
            serviceType: .verifyOtp,
            flowType: .single,
            cancellationToken: CancellationToken(),
            networkProvider: self.networkController,
            parseAndValidate: { (response: Ecliptix_Proto_Membership_VerifyCodeResponse) in
                                
                guard response.result != .invalidOtp else {
                    throw InternalValidationFailure.networkError(response.message)
                }
                                
                return .success(response)
            }
        )
        .Match(
            onSuccess: { response in
                self.uniqueIdentifier = response.membership.uniqueIdentifier
                self.shouldNavigateToPasswordSetUp = true
        }, onFailure: { error in
            self.errorMessage = error.message
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
