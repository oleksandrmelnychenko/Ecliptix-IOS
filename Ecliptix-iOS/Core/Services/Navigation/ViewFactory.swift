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

        case .phoneNumberVerification:
            PhoneNumberView(navigation: navigation)

        case .verificationCode(let phoneNumber):
            VerificationCodeView(navigation: navigation, phoneNumber: phoneNumber)
            
        case .passwordSetup(let verificationSessionId):
            PasswordSetupView(navigation: navigation, verificationSessionId: verificationSessionId)
            
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
