//
//  ChatMessage.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import Foundation

struct ReplyRef: Identifiable, Equatable {
    let id: UUID
    let author: String
    let preview: String
}

enum ChatMessageStatus {
    case sending
    case sent
    case delivered
    case read
    case failed
}

enum ChatMessageSide {
    case outgoing
    case incoming
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    var text: String
    var side: ChatMessageSide
    var time: String
    var createdAt: Date
    var updatedAt: Date?
    var status: ChatMessageStatus
    
    var replyTo: ReplyRef? = nil
    
    init(
        id: UUID = UUID(),
        text: String,
        side: ChatMessageSide,
        time: String,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        status: ChatMessageStatus = .sending,
        replyTo: ReplyRef? = nil
    ) {
        self.id = id
        self.text = text
        self.side = side
        self.time = time
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
        self.replyTo = replyTo
    }
    
    static func ==(lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

