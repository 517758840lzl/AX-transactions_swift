import SwiftUI

/// White block used by both `.ledger-panel` and `.ledger-card`.
struct PanelCard<Content: View>: View {
    var title: String?
    var trailing: AnyView?
    var titleSize: CGFloat = 16
    var card = false
    @ViewBuilder var content: () -> Content

    init(
        title: String? = nil,
        trailing: AnyView? = nil,
        titleSize: CGFloat = 16,
        card: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.trailing = trailing
        self.titleSize = titleSize
        self.card = card
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if title != nil || trailing != nil {
                HStack(alignment: .center, spacing: 10) {
                    if let title {
                        Text(title)
                            .font(.system(size: titleSize, weight: .bold))
                            .tracking(titleSize * -0.02)
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    trailing
                }
                .padding(.bottom, 12)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Palette.line.opacity(card ? 0.9 : 0.95), lineWidth: 1)
        )
        .plateShadow(opacity: card ? 0.04 : 0.05, radius: card ? 12 : 14, y: 10)
    }
}
