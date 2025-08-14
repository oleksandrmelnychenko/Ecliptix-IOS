//
//  ChatMessage.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import Foundation

enum MessageStatus {
    case sending
    case sent
    case delivered
    case read
    case failed(Error?)
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    var text: String
    var isSentByUser: Bool
    var createdAt: Date
    var updatedAt: Date?
    var status: MessageStatus

    init(
        id: UUID = UUID(),
        text: String,
        isSentByUser: Bool,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        status: MessageStatus = .sending
    ) {
        self.id = id
        self.text = text
        self.isSentByUser = isSentByUser
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
    }
    
    static func ==(lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

