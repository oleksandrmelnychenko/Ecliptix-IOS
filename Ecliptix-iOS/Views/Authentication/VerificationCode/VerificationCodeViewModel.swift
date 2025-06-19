//
//  VerificationCodeViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import Foundation

@MainActor
final class VerificationCodeViewModel: ObservableObject {
    public static let emptySign = "\u{200B}"
    
    @Published var codeDigits: [String] = Array(repeating: emptySign, count: 6)
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var secondsRemaining: Int = 0
    @Published var remainingTime: String = "00:00"

    private let phoneNumber: String
    private let navigation: NavigationService

    private let networkController: NetworkController
    private var validatePhoneNumberResponce: Ecliptix_Proto_Membership_ValidatePhoneNumberResponse? = nil
    private var verificationSessionIdentifier: UUID? = nil
    
    init(phoneNumber: String, navigation: NavigationService) {
        self.phoneNumber = phoneNumber
        self.navigation = navigation
        networkController = ServiceLocator.shared.resolve(NetworkController.self)
    }
    
    func startValidation() {
        Task {
            await validatePhoneNumber(phoneNumber: phoneNumber)
        }
    }

    var combinedCode: String {
        codeDigits.joined()
    }

    func verifyCode(onFailure: @escaping () -> Void) async {
        let code = combinedCode.replacingOccurrences(of: Self.emptySign, with: "")
        
        guard code.count == 6 else {
            await MainActor.run {
                self.errorMessage = Strings.VerificationCode.Errors.invalidCode
            }
            return
        }

        await sendVerificationCode()
    }

    func resetCode() {
        codeDigits = Array(repeating: Self.emptySign, count: 6)
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

    private func validatePhoneNumber(phoneNumber: String) async {
        let cancellationToken = CancellationToken()

        guard let systemDeviceIdentifier = await Self.systemDeviceIdentifier() else {
            errorMessage = "Invalid device ID"
            return
        }

        guard UUID(uuidString: phoneNumber) == nil else {
            errorMessage = "Phone number must not be a GUID"
            return
        }

        var request = Ecliptix_Proto_Membership_ValidatePhoneNumberRequest()
        request.phoneNumber = phoneNumber
        request.appDeviceIdentifier = Utilities.guidToByteArray(systemDeviceIdentifier)

        let connectId = Self.computeConnectId(pubKeyExchangeType: .dataCenterEphemeralConnect)

        do {
            _ = await networkController.executeServiceAction(
                connectId: connectId,
                serviceAction: .validatePhoneNumber,
                plainBuffer: try request.serializedData(),
                flowType: .single,
                onSuccessCallback: { [weak self] payload in
                    guard let self else {
                        return .failure(.unexpectedError("Self is nil"))
                    }

                    do {
                        self.validatePhoneNumberResponce = try Utilities.parseFromBytes(
                            Ecliptix_Proto_Membership_ValidatePhoneNumberResponse.self,
                            data: payload
                        )

                        if self.validatePhoneNumberResponce!.result == .invalidPhone {
                            self.errorMessage = self.validatePhoneNumberResponce!.message
                        } else {
                            await self.initiateVerification(
                                phoneNumberIdentifier: self.validatePhoneNumberResponce!.phoneNumberIdentifier,
                                type: .sendOtp
                            )
                        }

                        return .success(.value)
                    } catch {
                        debugPrint("Validation parsing error: \(error)")
                        return .failure(.generic("Failed to parse validation response", inner: error))
                    }
                },
                token: cancellationToken
            )
        } catch {
            debugPrint("Validation execution error: \(error)")
            errorMessage = "Network error during validation"
        }
    }

    
    private func initiateVerification(phoneNumberIdentifier: Data, type: Ecliptix_Proto_Membership_InitiateVerificationRequest.TypeEnum) async {
        let cancellationToken = CancellationToken()

        guard let systemDeviceIdentifier = await Self.systemDeviceIdentifier() else {
            errorMessage = "Invalid device ID"
            return
        }

        var request = Ecliptix_Proto_Membership_InitiateVerificationRequest()
        request.phoneNumberIdentifier = phoneNumberIdentifier
        request.appDeviceIdentifier = Utilities.guidToByteArray(systemDeviceIdentifier)
        request.purpose = .registration
        request.type = type

        let connectId = Self.computeConnectId(pubKeyExchangeType: .dataCenterEphemeralConnect)

        do {
            _ = await networkController.executeServiceAction(
                connectId: connectId,
                serviceAction: .initiateVerification,
                plainBuffer: try request.serializedData(),
                flowType: .receiveStream,
                onSuccessCallback: { [weak self] payload in
                    guard let self else {
                        return .failure(.unexpectedError("Self is nil"))
                    }

                    do {
                        let timerTick = try Utilities.parseFromBytes(
                            Ecliptix_Proto_Membership_VerificationCountdownUpdate.self,
                            data: payload
                        )

                        if timerTick.alreadyVerified {
                        }

                        if self.verificationSessionIdentifier == nil {
                            self.verificationSessionIdentifier = try Utilities.fromByteStringToGuid(timerTick.sessionIdentifier)
                        }

                        await MainActor.run {
                            self.secondsRemaining = Int(timerTick.secondsRemaining)
                            self.remainingTime = Self.formatRemainingTime(timerTick.secondsRemaining)
                        }

                        return .success(.value)
                    } catch {
                        debugPrint("Error parsing verification countdown: \(error)")
                        return .failure(.generic("Failed to parse countdown", inner: error))
                    }
                },
                token: cancellationToken
            )
        } catch {
            debugPrint("Verification execution error: \(error)")
            errorMessage = "Failed to initiate verification"
        }
    }

    private func sendVerificationCode() async {
        guard let systemDeviceIdentifier = await Self.systemDeviceIdentifier() else {
            await MainActor.run {
                self.errorMessage = "Invalid device ID"
            }
            return
        }
        
        await MainActor.run {
            self.errorMessage = nil
            self.isLoading = true
        }
        
        var verifyCodeRequest = Ecliptix_Proto_Membership_VerifyCodeRequest()
        verifyCodeRequest.code = combinedCode.replacingOccurrences(of: Self.emptySign, with: "")
        verifyCodeRequest.purpose = .registration
        verifyCodeRequest.appDeviceIdentifier = Utilities.guidToByteArray(systemDeviceIdentifier)
        
        let connectId = Self.computeConnectId(pubKeyExchangeType: .dataCenterEphemeralConnect)
        
        do {
            _ = await networkController.executeServiceAction(
                connectId: connectId,
                serviceAction: .verifyOtp,
                plainBuffer: try verifyCodeRequest.serializedData(),
                flowType: .single,
                onSuccessCallback: { [weak self] payload in
                    guard let self = self else {
                        return .failure(.unexpectedError("Object deallocated"))
                    }
                    
                    do {
                        let verifyCodeResponse = try Utilities.parseFromBytes(Ecliptix_Proto_Membership_VerifyCodeResponse.self, data: payload)
                        
                        await MainActor.run {
                            self.isLoading = false
                            
                            if verifyCodeResponse.result == .succeeded {
                                let membership = verifyCodeResponse.membership
                                
                                if let stringID = String(data: membership.uniqueIdentifier, encoding: .utf8) {
                                    self.navigation.navigate(to: .passwordSetup(stringID))
                                } else {
                                    print("Failed to parse Data to string.")
                                }

                            } else if verifyCodeResponse.result == .invalidOtp {
                                
                            }
                        }
                        
                        return .success(.value)
                    } catch {
                        await MainActor.run {
                            self.isLoading = false
                            self.errorMessage = "Failed to parse server response"
                        }
                        return .failure(.generic("Deserialization failed", inner: error))
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
    
    private static func formatRemainingTime(_ seconds: UInt64) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // move to ViewModelBase
    private static func systemDeviceIdentifier() async -> UUID? {
        let appInstanceInfo = ServiceLocator.shared.resolve(AppInstanceInfo.self)
        return await appInstanceInfo.systemDeviceIdentifier
    }
    
    private static func computeConnectId(pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType) -> UInt32 {
        let appInstanceInfo = ServiceLocator.shared.resolve(AppInstanceInfo.self)
        
        let connectId = Utilities.computeUniqueConnectId(
            appInstanceId: appInstanceInfo.appInstanceId,
            appDeviceId: appInstanceInfo.deviceId,
            contextType: pubKeyExchangeType)
        
        return connectId
    }
}
