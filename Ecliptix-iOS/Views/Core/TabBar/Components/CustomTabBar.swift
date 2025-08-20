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
                    .padding(.vertical, 10)
                    .overlay(alignment: .top) {
                        if selection == item.tab {
                            Capsule()
                                .frame(height: 3)
                                .matchedGeometryEffect(id: "underline", in: ns)
                                .offset(y: -6)
                        }
                    }
                }
                .buttonStyle(.plain)
                .overlay(alignment: .topTrailing) {
                    if let badge = item.badge, badge > 0 {
                        Text("\(badge)")
                            .font(.caption2).bold()
                            .padding(5)
                            .background(Circle().fill(.red))
                            .foregroundColor(.white)
                            .offset(x: 10, y: -8)
                            .accessibilityLabel("\(badge) new")
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(selection == item.tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(radius: 8, y: 3)
    }
}