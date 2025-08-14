//
//  HeaderMenu.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.08.2025.
//

import SwiftUI

struct SelectionHeader: View {
    @State var selectedCount: Int
    
    let onClear: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            Button(
                action: onClear,
                label: {
                    Text("Clear Chat")
                }
            )
            
            Spacer()
            
            Text("\(selectedCount) Selected")

            Spacer()
            
            Button(
                action: onCancel,
                label: {
                    Text("Cancel")
                }
            )
        }
    }
}

#Preview {
    SelectionHeader(selectedCount: 100, onClear: {}, onCancel: {})
}
