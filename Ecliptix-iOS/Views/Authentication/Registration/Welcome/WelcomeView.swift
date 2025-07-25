//
//  WelcomeView.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 20.05.2025.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var navigation: NavigationService
    @EnvironmentObject private var localization: LocalizationService
    @StateObject private var viewModel: WelcomeViewModel

    init() {
        _viewModel = StateObject(wrappedValue: WelcomeViewModel())
        
    }

    var body: some View {
        AuthScreenContainer(spacing: 0) {
            VStack {
                HStack {
                    Spacer()
                    
                    WelcomeHeader()
                        .padding(.top, 10)
                    
                    Spacer()
                }


                HStack {
                    Spacer()
                    Image("BackgroundImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 330, height: 370)
                    Spacer()
                }
                
                Spacer()

                HStack {
                    // Sign in
                    PrimaryButton(
                        title: Strings.Welcome.signInButton,
                        isEnabled: self.viewModel.isSignInEnabled,
                        isLoading: self.viewModel.isSignInLoading,
                        style: .light,
                        action: viewModel.continueToSignIn
                    )
                    
                    // Create new account
                    PrimaryButton(
                        title: Strings.Welcome.createAccountButton,
                        isEnabled: self.viewModel.isCreateAccountEnabled,
                        isLoading: self.viewModel.isCreateAccountLoading,
                        style: .dark,
                        action: viewModel.continueToPhoneNumber
                    )
                }
            }
        }
        .onChange(of: viewModel.shouldNavigateToSignIn) { _, shouldNavigate in
            if shouldNavigate {
                navigation.navigate(to: .signIn)
                
                DispatchQueue.main.async {
                    viewModel.shouldNavigateToSignIn = false
                }
            }
        }
        .onChange(of: viewModel.shouldNavigateToSignUp) { _, shouldNavigate in
            if shouldNavigate {
                navigation.navigate(to: .phoneNumberVerification(authFlow: .registration))
                
                DispatchQueue.main.async {
                    viewModel.shouldNavigateToSignUp = false
                }
            }
        }
    }
}


#Preview {
    let navService = NavigationService()
    let locService = LocalizationService.shared
    return WelcomeView()
        .environmentObject(navService)
        .environmentObject(locService)
}

#Preview("ContentView Landscape", traits: .landscapeRight, body: {
    let navService = NavigationService()
    let locService = LocalizationService.shared
    return WelcomeView()
        .environmentObject(navService)
        .environmentObject(locService)
})

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let navService = NavigationService()
        let locService = LocalizationService.shared
        return WelcomeView()
            .environmentObject(navService)
            .environmentObject(locService)
    }
}
