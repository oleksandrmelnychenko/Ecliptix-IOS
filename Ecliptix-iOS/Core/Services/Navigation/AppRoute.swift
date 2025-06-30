//
//  AppRoute.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.06.2025.
//


import SwiftUICore

enum AppRoute: Hashable {
    case welcome
    
    case phoneNumberVerification
    case verificationCode(String)
    case passwordSetup(Data)
    case passPhaseRegistration
    
    case signIn
    case passPhaseLogin
    
    case test
}