//
//  ChatsOverviewView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 05.08.2025.
//

import SwiftUI

// MARK: - Main
struct ChatsOverviewView: View {
    @State private var searchText = ""
    @State private var mode: ChatsMode = .browsing
    @State private var selected: Set<Int> = []
    @State private var visibleChats: [Chat] = []
    @State private var currentPage = 1
    
    private let pageSize = 50
    private let totalChats = 200
    
    private func chat(for id: Int) -> Chat {
        .init(
            id: id,
            name: "Chat \(id)",
            lastMessage: "Message from chat \(id)",
            unread: id % 10,
            lastDate: Date().addingTimeInterval(TimeInterval(-id * 60))
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SearchBar(text: $searchText)
                        .padding(.horizontal)

                    LazyVStack(spacing: 12) {
                        ForEach(visibleChats) { chat in
                            ChatRow(
                                chat: chat,
                                mode: mode,
                                isSelected: selected.contains(chat.id)
                            ) {
                                toggle(chat.id)
                            }
                            .onAppear {
                                loadMoreIfNeeded(current: chat)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.large)

            // Hide tab bar in selecting mode
//            .toolbar(mode == .selecting ? .hidden : .automatic, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ChatsTopMenu(mode: $mode, clearSelection: { selected.removeAll() })
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if mode == .selecting {
                        EmptyView()
                    } else {
                        Button { /* new chat */ } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
            }
            .toolbar {
                if mode == .selecting {
                    SelectionToolbar(
                        canAct: !selected.isEmpty,
                        onMute: { /* mute */ },
                        onArchive: { /* archive */ },
                        onDelete: { /* delete */ }
                    )
                }
            }
            .onAppear {
                loadPage(reset: true)
            }
            .onChange(of: searchText) {
                loadPage(reset: true)
            }
        }
    }
    
    private func loadPage(reset: Bool) {
        if reset {
            currentPage = 1
            visibleChats.removeAll()
        }
        
        let start = (currentPage - 1) * pageSize
        let end = start + pageSize
        
        let newChats: [Chat]
        if searchText.isEmpty {
            newChats = (start..<min(end, totalChats)).map { chat(for: $0) }
        } else {
            newChats = (0..<totalChats)
                .lazy
                .map { chat(for: $0) }
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .dropFirst(start)
                .prefix(pageSize)
                .map { $0 }
        }
        
        visibleChats.append(contentsOf: newChats)
        currentPage += 1
    }
    
    private func loadMoreIfNeeded(current chat: Chat) {
        guard let last = visibleChats.last else { return }
        if chat.id == last.id {
            loadPage(reset: false)
        }
    }
    
    private func toggle(_ id: Int) {
        if selected.contains(id) {
            selected.remove(id)
        } else {
            selected.insert(id)
        }
    }
}


#Preview {
    ChatsOverviewView()
}
