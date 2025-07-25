//
//  InternetConnectionView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 24.07.2025.
//

import SwiftUI

struct InternetConnectionView: View {
    
    @State private var pulsate: Bool = false
    @ObservedObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        let connectionMessage = networkMonitor.isConnected
            ? String(localized: "Internet connection")
            : String(localized: "No internet connection")
            
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.body)
                    Text(connectionMessage)
                        .font(.body)
                    
                    Spacer()
                }
            }
            
            VStack(spacing: 4) {
                Circle()
                    .fill((networkMonitor.isConnected ? Color.green : Color.red).opacity(pulsate ? 1.0 : 0.4))
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulsate ? 1.2 : 1)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulsate)
                    .onAppear { pulsate = true }
            }
        }
        .padding()
        .background(Color("DarkButton.BackgroundColor"))
        .cornerRadius(8)
        .foregroundColor(.white)
        .padding(.horizontal)
        .transition(.move(edge: .top))
    }
}

#Preview {
    let connectionService = NetworkMonitor()
    InternetConnectionView(networkMonitor: connectionService)
}
