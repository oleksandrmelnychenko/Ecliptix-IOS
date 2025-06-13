//
//  TestView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//

import SwiftUI

struct TestView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "globe")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(.horizontal)
        }
        .padding(.horizontal, 24)
        .padding(.top, 100)
    }
}
