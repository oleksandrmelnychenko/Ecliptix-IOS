//
//  Chat.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 08.08.2025.
//


import SwiftUI

struct Chat: Identifiable {
    let id: Int
    let name: String
    let lastSeenOnline: String
    let lastMessage: String
    
    let unread: Int
    let lastDate: Date
}
