//
//  ChatMessage.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isSentByUser: Bool
    let createdAt: Date
    let updatedAt: Date

    init(id: UUID = UUID(),
         text: String,
         isSentByUser: Bool,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.text = text
        self.isSentByUser = isSentByUser
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
