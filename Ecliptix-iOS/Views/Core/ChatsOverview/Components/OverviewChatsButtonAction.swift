//
//  OverviewChatsButtonAction.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 07.08.2025.
//


import SwiftUI

struct OverviewChatsButtonAction: View {
    @Binding var isSelectingChats: Bool
    @Binding var selectedChats: Set<Int>
    
    var body: some View {
        if isSelectingChats {
            Button(action: {
                isSelectingChats = false
                selectedChats.removeAll()
            }, label: {
                Text("Done")
            })
        } else {
            Menu {
                Button(
                    action: {
                    },
                    label: {
                        HStack {
                            Text("Read all")
                            Image(systemName: "checkmark.bubble")
                        }
                    }
                )
                
                Button(
                    action: {
                        isSelectingChats = true
                    },
                    label: {
                        HStack {
                            Text("Select chats")
                            Image(systemName: "checkmark.circle")
                        }
                    }
                )
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .padding(12)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
        }
    }
}
