//
//  WelcomeViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 12.06.2025.
//

import Foundation

@MainActor
final class WelcomeViewModel: ObservableObject {
        
    @Published var isSignInEnabled: Bool = true
    @Published var isCreateAccountEnabled: Bool = true
    @Published var isSignInLoading: Bool = false
    @Published var isCreateAccountLoading: Bool = false
    
    private let navigation: NavigationService

    init(navigation: NavigationService) {
        self.navigation = navigation
    }


    func continueToPhoneNumber() {
        guard self.isCreateAccountEnabled else { return }
        
        self.isCreateAccountLoading = true
        self.navigation.navigate(to: .phoneNumberVerification(authFlow: .registration))
        self.isCreateAccountLoading = false
    }

    func continueToSignIn() {
        guard self.isSignInEnabled else { return }
        
        self.isSignInLoading = true
        self.navigation.navigate(to: .signIn)
        self.isSignInLoading = false
    }
}
