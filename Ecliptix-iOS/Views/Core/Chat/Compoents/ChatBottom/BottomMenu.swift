//
//  BottomMenu.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.08.2025.
//

import SwiftUI

struct BottomMenu: View {
    let onDelete: () -> Void
    let onSend: () -> Void
    let onForward: () -> Void
    
    var body: some View {
        HStack {
            Button(
                action: {
                    onDelete()
                },
                label: {
                    Image(systemName: "trash")
            })
            
            Spacer()
            
            Button(
                action: {
                    onSend()
                },
                label: {
                    Text("Send?")
            })
            
            Spacer()
            
            Button(
                action: {
                    onForward()
                },
                label: {
                    Image(systemName: "arrowshape.turn.up.right")
            })
        }
    }
}

#Preview {
    BottomMenu(onDelete: {}, onSend: {}, onForward: {})
}
