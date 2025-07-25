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

    @Published var shouldNavigateToSignIn = false
    @Published var shouldNavigateToSignUp = false
    
    func continueToPhoneNumber() {
        guard self.isCreateAccountEnabled else { return }
        
        self.shouldNavigateToSignUp = true
    }

    func continueToSignIn() {
        guard self.isSignInEnabled else { return }
        
        self.shouldNavigateToSignIn = true
    }
}
