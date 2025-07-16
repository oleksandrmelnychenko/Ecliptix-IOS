//
//  AppRoute.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.06.2025.
//


import SwiftUICore

enum AppRoute: Hashable {
    case welcome
    
    case phoneNumberVerification(authFlow: AuthFlow)
    case verificationCode(phoneNumber: String, phoneNumberIdentifier: Data, authFlow: AuthFlow)
    case passwordSetup(verificationSessionId: Data, authFlow: AuthFlow)
    case passPhaseRegistration
    
    case signIn
    case passPhaseLogin
    
    case test
}
