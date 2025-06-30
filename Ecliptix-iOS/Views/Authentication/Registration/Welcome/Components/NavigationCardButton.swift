//
//  NavigationCardButton.swift
//  Ecliptix-iOS-Views
//
//  Created by Oleksandr Melnechenko on 02.06.2025.
//


import SwiftUI

//struct NavigationCardButton<Destination: View>: View {
//    let title: String
//    let subtitle: String
//    let foreground: Color
//    let background: Color
//    let border: Bool
//    let destination: Destination
//    
//    var body: some View {
//        NavigationLink(destination: destination) {
//            HStack {
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(title)
//                        .font(.headline)
//                        .foregroundColor(foreground)
//                    Text(subtitle)
//                        .font(.subheadline)
//                        .foregroundColor(foreground.opacity(0.6))
//                }
//
//                Spacer()
//
//                Image(systemName: "chevron.right")
//                    .foregroundColor(foreground.opacity(0.6))
//            }
//            .padding()
//            .background(background)
//            .cornerRadius(12)
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(border ? foreground : .clear, lineWidth: border ? 1 : 0)
//            )
//        }
//    }
//}
//
//#Preview {
//    NavigationStack {
//        NavigationCardButton(
//            title: "Title",
//            subtitle: "Description",
//            foreground: .white,
//            background: .black,
//            border: false,
//            destination: Text("Main Destination")
//        )
//        .padding()
//    }
//}
//
//#Preview {
//    NavigationStack {
//        NavigationCardButton(
//            title: "Title",
//            subtitle: "Description",
//            foreground: .black,
//            background: .white,
//            border: true,
//            destination: Text("Alternative Destination")
//        )
//        .padding()
//    }
//}

import SwiftUI

struct NavigationCardButton: View {
    let title: String
    let subtitle: String
    let foreground: Color
    let background: Color
    let border: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(foreground)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(foreground.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(foreground.opacity(0.6))
        }
        .padding()
        .background(background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(border ? foreground : .clear, lineWidth: border ? 1 : 0)
        )
    }
}

#Preview {
    NavigationCardButton(
        title: "Title",
        subtitle: "Description",
        foreground: .white,
        background: .black,
        border: false
    )
    .padding()
}

#Preview {
    NavigationCardButton(
        title: "Title",
        subtitle: "Description",
        foreground: .black,
        background: .white,
        border: true
    )
    .padding()
}
