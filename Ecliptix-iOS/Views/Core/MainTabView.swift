//
//  MainTabView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 06.08.2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            StatusesView()
                .tabItem {
                    Image(systemName: "circle.dashed")
                    Text("Status")
                }
            
            ChatsOverviewView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Chats")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}

#Preview {
    MainTabView()
}
