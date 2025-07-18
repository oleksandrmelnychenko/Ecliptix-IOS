//
//  WelcomeView.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 20.05.2025.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var navigation: NavigationService
    @StateObject private var viewModel: WelcomeViewModel

    init(navigation: NavigationService) {
        _viewModel = StateObject(wrappedValue: WelcomeViewModel(navigation: navigation))
        
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
                        title: String(localized: "Sign In"),
                        isEnabled: self.viewModel.isSignInEnabled,
                        isLoading: self.viewModel.isSignInLoading,
                        style: .light,
                        action: viewModel.continueToSignIn
                    )
                    
                    // Create new account
                    PrimaryButton(
                        title: String(localized: "Create account"),
                        isEnabled: self.viewModel.isCreateAccountEnabled,
                        isLoading: self.viewModel.isCreateAccountLoading,
                        style: .dark,
                        action: viewModel.continueToPhoneNumber
                    )
                }
            }
            
        }
    }
}


#Preview {
    let navService = NavigationService()
    return WelcomeView(navigation: navService)
        .environmentObject(navService)
}

#Preview("ContentView Landscape", traits: .landscapeRight, body: {
    let navService = NavigationService()
    return WelcomeView(navigation: navService)
        .environmentObject(navService)
})

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let navService = NavigationService()
        return WelcomeView(navigation: navService)
            .environmentObject(navService)
    }
}
