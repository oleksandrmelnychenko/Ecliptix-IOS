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

    init(navigation: NavigationService) {
        _viewModel = StateObject(wrappedValue: WelcomeViewModel(navigation: navigation))
        
    }

    var body: some View {
        AuthScreenContainer(spacing: 0, showLogo: false, showLicense: false, content:  {
            Image("EcliptixLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .padding(.horizontal)

            WelcomeHeader()
                .padding(.horizontal)
                .padding(.top, 10)
                .id(localization.languageChanged)

            Spacer()

            TermsAndConditions(agreedToTerms: $viewModel.agreedToTerms)
                .padding(.bottom, 10)

            // Create new account
            NavigationCardButton(
                title: String(localized: "New account"),
                subtitle: String(localized: "Create new Worldcoin account"),
                foreground: .white,
                background: .black,
                border: false
            )
            .onTapGesture {
                if viewModel.agreedToTerms {
                    viewModel.continueToPhoneNumber()
                }
            }            

            // Sign in
            NavigationCardButton(
                title: String(localized: "Existing account"),
                subtitle: String(localized: "Restore account from a backup"),
                foreground: .black,
                background: .white,
                border: true
            )
            .padding(.top, 15)
            .onTapGesture {
                if viewModel.agreedToTerms {
                    viewModel.continueToSignIn()
                }
            }
        })
    }
}


#Preview {
    let navService = NavigationService()
    let locService = LocalizationService.shared
    return WelcomeView(navigation: navService)
        .environmentObject(navService)
        .environmentObject(locService)
}

#Preview("ContentView Landscape", traits: .landscapeRight, body: {
    let navService = NavigationService()
    let locService = LocalizationService.shared
    return WelcomeView(navigation: navService)
        .environmentObject(navService)
        .environmentObject(locService)
})

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let navService = NavigationService()
        let locService = LocalizationService.shared
        return WelcomeView(navigation: navService)
            .environmentObject(navService)
            .environmentObject(locService)
    }
}
