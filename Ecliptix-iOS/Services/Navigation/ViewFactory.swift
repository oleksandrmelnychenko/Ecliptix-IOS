//
//  ViewFactory.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import SwiftUI

struct ViewFactory {
    
    @ViewBuilder
    static func view(for route: AppRoute) -> some View {
        switch route {
        case .welcome:
            WelcomeView()

        case .phoneNumberVerification(let authFlow):
            PhoneNumberView(authFlow: authFlow)

        case let .verificationCode(phoneNumberIdentifier: phoneNumberIdentifier, authFlow: authFlow):
            VerificationCodeView(phoneNumberIdentifier: phoneNumberIdentifier, authFlow: authFlow)
            
        case let .passwordSetup(verificationSessionId: verificationSessionId, authFlow: authFlow):
            PasswordSetupView(verificationSessionId: verificationSessionId, authFlow: authFlow)
            
        case .passPhaseRegistration:
            PassPhaseRegisterView()
            
        case .signIn:
            SignInView()
            
        case .passPhaseLogin:
            TestView()
            
        case .test:
            TestView()
        }
    }
}
