//
//  InternetConnectionView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 24.07.2025.
//

import SwiftUI

struct InternetConnectionView: View {
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.body)
                    Text(String(localized: "No internet connection"))
                        .font(.body)
                    
                    Spacer()
                }
            }
            
            VStack(spacing: 4) {
                Circle()
                    .foregroundColor(.red)
                    .frame(width: 8, height: 8)
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
    InternetConnectionView()
}
