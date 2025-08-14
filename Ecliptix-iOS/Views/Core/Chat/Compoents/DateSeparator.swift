//
//  DateSeparator.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.08.2025.
//


import SwiftUI

struct DateSeparator: View {
    let date: Date

    var body: some View {
        HStack {
            Spacer()
            Text(Self.title(for: date))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private static let monthDay: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "LLLL d"
        df.locale = .current
        return df
    }()

    private static func title(for date: Date) -> String {
        let raw = monthDay.string(from: date)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }
}
