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

    private let phoneNumber: String
    private let navigation: NavigationService

    init(phoneNumber: String, navigation: NavigationService) {
        self.phoneNumber = phoneNumber
        self.navigation = navigation
    }

    var combinedCode: String {
        codeDigits.joined()
    }

    func verifyCode(onFailure: @escaping () -> Void) {
        let code = combinedCode.replacingOccurrences(of: Self.emptySign, with: "")
        
        guard code.count == 6 else { return }
        
        errorMessage = nil
        isLoading = true
        
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            
            await MainActor.run {
                guard let self else { return }
                self.isLoading = false
                
                if code == "123456" {
                    self.navigation.navigate(to: .passwordSetup)
                } else {
                    self.errorMessage = Strings.VerificationCode.Errors.invalidCode
                    self.resetCode()
                    onFailure()
                }
            }
        }
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

}
