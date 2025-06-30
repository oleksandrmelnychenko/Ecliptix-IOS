//
//  WelcomeViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 12.06.2025.
//

import Foundation

@MainActor
final class WelcomeViewModel: ObservableObject {
    @Published var agreedToTerms: Bool = false
    
    private let navigation: NavigationService

    init(navigation: NavigationService) {
        self.navigation = navigation
    }


    func continueToPhoneNumber() {
        guard agreedToTerms else { return }
        navigation.navigate(to: .phoneNumberVerification)
    }

    func continueToSignIn() {
        guard agreedToTerms else { return }
        navigation.navigate(to: .signIn)
    }
    
    func continueToTestView() {
        guard agreedToTerms else { return }        
        navigation.navigate(to: .test)
    }
}
