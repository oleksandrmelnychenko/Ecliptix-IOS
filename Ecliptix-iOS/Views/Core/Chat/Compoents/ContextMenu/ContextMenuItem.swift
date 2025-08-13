//
//  ContextMenuItem.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.08.2025.
//

import SwiftUI

struct ContextMenuItem: View {
    private let sf: String
    private let title: String
    private let showDivider: Bool
    private let tint: Color
    private let action: () -> Void
    
    init(sf: String, title: String, showDivider: Bool? = true, tint: Color? = .primary, action: @escaping () -> Void) {
        self.sf = sf
        self.title = title
        self.showDivider = showDivider!
        self.tint = tint!
        self.action = action
    }
    
    var body: some View {
        Button(action: { action() }) {
            VStack {
                HStack(spacing: 4) {
                    Text(title)
                    
                    Spacer()
                    
                    Image(systemName: sf)
                }
                .foregroundColor(tint)
                .padding(.horizontal, 18)
                
                if showDivider {
                    Divider()
                }
            }
            
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContextMenuItem(
        sf: "arrowshape.turn.up.left",
        title: "Reply",
        action: {}
    )
}
