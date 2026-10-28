import SwiftUI

struct DashboardCategoriesPanel: View {
    @ObservedObject var screen: LedgerScreen
    var copy: LedgerCopy
    var mark: String
    var parts: [CategoryPart]

    var body: some View {
        if !parts.isEmpty {
            PanelCard(title: copy.monthCategories, trailing: AnyView(
                Button(copy.report) { screen.tab = 1 }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.ink)
            )) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(parts) { part in
                            chip(part)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.bottom, 6)
                    .immediateScroll()
                }
            }
        }
    }

    private func chip(_ part: CategoryPart) -> some View {
        let tint = Palette.slice(part.colorIndex)
        return Button {
            screen.category = part.name
            screen.tab = 1
        } label: {
            VStack(spacing: 5) {
                Text(part.name)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(-0.28)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Text(LedgerMoney.text(part.amount, mark: mark))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Palette.muted)
                    .monospacedDigit()
            }
            .padding(EdgeInsets(top: 14, leading: 16, bottom: 16, trailing: 16))
            .frame(minWidth: 96)
            .background(mix(Color.white, with: tint, share: 0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(mix(Palette.line, with: tint, share: 0.28), lineWidth: 1)
            )
            .overlay(alignment: .bottom) { capBar(part, tint: tint) }
            .plateShadow(opacity: 0.04, radius: 10, y: 8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func capBar(_ part: CategoryPart, tint: Color) -> some View {
        if let cap = part.budgetCap, cap > 0 {
            let ratio = min(max(part.amount / cap, 0), 1)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.wash)
                    Capsule()
                        .fill(ratio >= 1 ? Palette.down : tint)
                        .frame(width: proxy.size.width * ratio)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    /// `color-mix(in srgb, tint share%, base)`.
    private func mix(_ base: Color, with tint: Color, share: CGFloat) -> Color {
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, ta: CGFloat = 0
        UIColor(base).getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        UIColor(tint).getRed(&tr, green: &tg, blue: &tb, alpha: &ta)
        let keep = 1 - share
        return Color(
            red: Double(tr * share + br * keep),
            green: Double(tg * share + bg * keep),
            blue: Double(tb * share + bb * keep)
        )
    }
}
