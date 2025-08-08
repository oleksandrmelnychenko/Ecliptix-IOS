//
//  TextMessage.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct TextMessage: View {
    let message: ChatMessage
    
    var body: some View {
        Text(message.text)
            .padding(10)
            .background(message.isSentByUser ? Color.blue : Color.gray.opacity(0.3))
            .foregroundColor(message.isSentByUser ? .white : .black)
            .cornerRadius(12)
            .frame(maxWidth: 250, alignment: message.isSentByUser ? .trailing : .leading)
    }
}