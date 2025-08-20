//
//  CustomTabBar.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 20.08.2025.
//


import SwiftUI

struct CustomTabBar: View {
    @Binding var selection: MainTab
    let items: [TabItem]

    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    selection = item.tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                        Text(item.title)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                }
//                .overlay(alignment: .topTrailing) {
//                    if let badge = item.badge, badge > 0 {
//                        Text("\(badge)")
//                            .font(.caption2).bold()
//                            .padding(5)
//                            .background(Circle().fill(.red))
//                            .foregroundColor(.white)
//                            .offset(x: 10, y: -8)
//                            .accessibilityLabel("\(badge) new")
//                    }
//                }
            }
        }
        .background(.bar)
    }
}

#Preview {
    @Previewable @State var selection: MainTab = .chats
    
    CustomTabBar(
        selection: $selection,
        items: [
            .init(tab: .status,   title: "Status",   systemImage: "circle.dashed"),
            .init(tab: .chats,    title: "Chats",    systemImage: "bubble.left.and.bubble.right.fill", badge: 3),
            .init(tab: .settings, title: "Settings", systemImage: "gear")
        ]
    )
}
