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
        AuthScreenContainer(spacing: 0, content:  {
            Image(systemName: "globe")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(.horizontal)

            WelcomeHeader()
                .padding(.horizontal)
                .padding(.top, 10)

            Spacer()

            TermsAndConditions(agreedToTerms: $viewModel.agreedToTerms)
                .padding(.bottom, 10)

            // Create new account
            NavigationCardButton(
                title: Strings.Welcome.NavigationCard_Main.title,
                subtitle: Strings.Welcome.NavigationCard_Main.subtitle,
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
                title: Strings.Welcome.NavigationCard_Alternative.title,
                subtitle: Strings.Welcome.NavigationCard_Alternative.subtitle,
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
