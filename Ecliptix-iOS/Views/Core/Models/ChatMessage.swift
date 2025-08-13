//
//  ChatMessage.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import Foundation

enum ChatMessageStatus {
    case sending
    case sent
    case delivered
    case read
    case failed(Error?)
}

struct ChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isSentByUser: Bool
    let createdAt: Date
    let updatedAt: Date
    var status: ChatMessageStatus

    init(
        id: UUID = UUID(),
        text: String,
        isSentByUser: Bool,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        status: ChatMessageStatus = .sending
    ) {
        self.id = id
        self.text = text
        self.isSentByUser = isSentByUser
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
    }
}

