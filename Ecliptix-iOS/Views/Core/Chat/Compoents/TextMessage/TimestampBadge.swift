//
//  TimestampBadge.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.08.2025.
//

import SwiftUI
import Foundation

struct TimestampBadge: View {
    let date: Date
    let status: MessageStatus
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(Self.timeFormatter.string(from: date))
            
            ChatMessageStatusView(status: status)
        }
        .font(.caption2)
        .foregroundColor(tint.opacity(0.9))
        .padding(.bottom, -6)
    }
    
    
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
}

#Preview {
    TimestampBadge(date: Date(), status: .delivered, tint: .primary)
}
