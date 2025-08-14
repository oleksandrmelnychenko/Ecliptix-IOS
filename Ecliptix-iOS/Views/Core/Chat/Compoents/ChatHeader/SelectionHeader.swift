//
//  HeaderMenu.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.08.2025.
//

import SwiftUI

struct SelectionHeader: View {
    @State var selectionCount: Int
    
    let clearChat: () -> Void
    let cancel: () -> Void
    
    var body: some View {
        HStack {
            Button(
                action: clearChat,
                label: {
                    Text("Clear Chat")
                }
            )
            
            Spacer()
            
            Text("\(selectionCount) Selected")

            Spacer()
            
            Button(
                action: cancel,
                label: {
                    Text("Cancel")
                }
            )
        }
    }
}

#Preview {
    SelectionHeader(selectionCount: 100, clearChat: {}, cancel: {})
}
