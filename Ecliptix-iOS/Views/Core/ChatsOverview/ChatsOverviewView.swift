//
//  ChatsOverviewView.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 05.08.2025.
//

import SwiftUI

struct ChatsOverviewView: View {
    var allowsMultipleSelection: Bool = true
    var onPick: ([Chat]) -> Void
    var onCancel: () -> Void = {}

    @State private var searchText = ""
    @State private var mode: ChatsMode = .browsing
    @State private var selected: Set<Int> = []
    @State private var visibleChats: [Chat] = []
    @State private var currentPage = 1
    
    private let pageSize = 200
    private let totalChats = 200_000
    
    private func chat(for id: Int) -> Chat {
        .init(
            id: id,
            name: "Chat \(id)",
            lastMessage: "Message from chat \(id)",
            unread: id % 10,
            lastDate: Date().addingTimeInterval(TimeInterval(-id * 60))
        )
    }

    private var selectedChats: [Chat] {
        visibleChats.filter { selected.contains($0.id) }
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
                                if allowsMultipleSelection || mode == .selecting {
                                    toggle(chat.id)
                                } else {
                                    // одразу віддаємо вибір і закриваємося зверху через onPick
                                    onPick([chat])
                                }
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

            .toolbar {
                // leading: Cancel
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                }

                // trailing: "Forward (N)" у selection або коли multi-select дозволений
                ToolbarItem(placement: .topBarLeading) {
                    if allowsMultipleSelection || mode == .selecting {
                        Button {
                            let picks = selectedChats
                            guard !picks.isEmpty else { return }
                            onPick(picks)
                        } label: {
                            if selected.isEmpty {
                                Text("Forward")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Forward (\(selected.count))")
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(selected.isEmpty)
                    } else {
                        Button { /* new chat */ } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
                
                // center/leading: твій існуючий top menu (опційно)
                ToolbarItem(placement: .topBarTrailing) {
                    ChatsTopMenu(mode: $mode, clearSelection: { selected.removeAll() })
                }
            }

            // нижній тулбар для масових дій — залишаю як у тебе
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
                // якщо шит запущено тільки заради форварду в один чат — залишаємо browsing
                // якщо точно хочеш мультивибір — можна форснути:
                if allowsMultipleSelection { mode = .selecting }
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
            selected.removeAll()
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
    ChatsOverviewView(onPick: {_ in })
}
