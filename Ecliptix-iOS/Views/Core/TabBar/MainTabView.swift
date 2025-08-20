//
//  MainTabView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 06.08.2025.
//

import SwiftUI

enum MainTab: Hashable { case status, chats, settings }

struct MainTabView: View {
    @State private var selection: MainTab = .chats

    var body: some View {
        ZStack {
            Group {
                switch selection {
                case .status:   StatusesView()
                case .chats:    ChatsOverviewView(onPick: { _ in })
                case .settings: SettingsView()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            CustomTabBar(
                selection: $selection,
                items: [
                    .init(tab: .status,   title: "Status",   systemImage: "circle.dashed"),
                    .init(tab: .chats,    title: "Chats",    systemImage: "bubble.left.and.bubble.right.fill", badge: 3),
                    .init(tab: .settings, title: "Settings", systemImage: "gear")
                ]
            )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct TabItem: Identifiable {
    let id = UUID()
    let tab: MainTab
    let title: String
    let systemImage: String
    var badge: Int? = nil
}

#Preview {
    MainTabView()
}
