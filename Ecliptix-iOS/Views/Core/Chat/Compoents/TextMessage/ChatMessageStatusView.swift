//
//  ChatMessageStatus.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.08.2025.
//

import SwiftUI

struct ChatMessageStatusView: View {
    private var status: ChatMessageStatus
    
    init(status: ChatMessageStatus) {
        self.status = status
    }
    
    var body: some View {
        Image(systemName: statusSymbolName)
            .imageScale(.small)
            .font(.caption2)
    }
    
    private var statusSymbolName: String {
        switch status {
        case .sending:            
            return "clock"
        case .sent:               
            return "checkmark"
        case .delivered:          
            return "checkmark.circle"
        case .read:               
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle"
        }
    }
}

#Preview("Sending") {
    ChatMessageStatusView(status: .sending)
}

#Preview("Sent") {
    ChatMessageStatusView(status: .sent)
}

#Preview("Delivered") {
    ChatMessageStatusView(status: .delivered)
}

#Preview("Read") {
    ChatMessageStatusView(status: .read)
}

#Preview("Failed") {
    ChatMessageStatusView(status: .failed(nil))
}
