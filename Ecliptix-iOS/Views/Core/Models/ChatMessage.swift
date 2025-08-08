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
}