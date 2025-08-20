//
//  InlineReplySnippet.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 15.08.2025.
//

import SwiftUI

struct ReplySnippetView: View {
    let isOutgoing: Bool
    let author: String
    let preview: String
    
    
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .frame(width: 3, height: 38)
                .cornerRadius(1.5)
                .foregroundStyle(isOutgoing ? .white.opacity(0.7) : .blue.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(author)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(isOutgoing ? .white : .blue)
                
                Text(preview)
                    .font(.caption2)
                    .foregroundStyle(isOutgoing ? .white.opacity(0.9) : .secondary)
            }
        }
    }
}

#Preview {
    ReplySnippetView(isOutgoing: false, author: "Oleksandr Melnechenko", preview: "Lorem ipsum dolor sit amet")
}
