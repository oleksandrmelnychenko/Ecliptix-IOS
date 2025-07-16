//
//  ViewFactory.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import SwiftUICore



struct ViewFactory {
    @ViewBuilder
    static func view(for route: AppRoute, with navigation: NavigationService) -> some View {
        switch route {
        case .welcome:
            WelcomeView(navigation: navigation)

        case .phoneNumberVerification(let authFlow):
            PhoneNumberView(navigation: navigation, authFlow: authFlow)

        case let .verificationCode(phoneNumber: phoneNumber, phoneNumberIdentifier: phoneNumberIdentifier, authFlow: authFlow):
            VerificationCodeView(navigation: navigation, phoneNumber: phoneNumber, phoneNumberIdentifier: phoneNumberIdentifier, authFlow: authFlow)
            
        case let .passwordSetup(verificationSessionId: verificationSessionId, authFlow: authFlow):
            PasswordSetupView(navigation: navigation, verificationSessionId: verificationSessionId, authFlow: authFlow)
            
        case .passPhaseRegistration:
            PassPhaseRegisterView(navigation: navigation)
            
        case .signIn:
            SignInView(navigation: navigation)
            
        case .passPhaseLogin:
            TestView()
            
        case .test:
            TestView()
        }
    }
}
