import Combine
import SwiftUI

struct DashboardBudgetPanel: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    var copy: LedgerCopy
    var monthOut: Double
    var budget: Double?
    var left: Double?
    var safe: Double?
    var pace: Bool

    var body: some View {
        if let budget, budget > 0, let left {
            PanelCard(title: copy.monthlyBudget, trailing: AnyView(
                Button(copy.edit) { screen.open(.budget) }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.ink)
            )) {
                filled(budget: budget, left: left)
            }
        } else {
            PanelCard {
                Button { screen.open(.budget) } label: {
                    HStack {
                        Text(copy.budgetUnset)
                            .font(.system(size: 16, weight: .bold))
                            .tracking(-0.32)
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Text("›")
                            .font(.system(size: 20))
                            .foregroundStyle(Palette.muted)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func filled(budget: Double, left: Double) -> some View {
        let over = left < 0
        let ratio = min(max(monthOut / budget, 0), 1)
        return VStack(alignment: .leading, spacing: 0) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.neutral)
                    Capsule().fill(Palette.pink).frame(width: proxy.size.width * ratio)
                }
            }
            .frame(height: 8)
            Text(over ? copy.budgetOver : copy.budgetRemaining)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(over ? Palette.review : Palette.muted)
                .padding(.top, 10)
            HStack(spacing: 0) {
                MoneyText(value: left, mark: store.book.mark, size: 13, signed: over)
                Text(" / ")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.muted.opacity(0.8))
                MoneyText(value: budget, mark: store.book.mark, size: 13)
            }
            if let safe, safe >= 0 {
                HStack(spacing: 0) {
                    Text(copy.safeToSpend + " ")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.muted)
                    MoneyText(value: safe, mark: store.book.mark, size: 13)
                }
                .padding(.top, 6)
            }
            if pace {
                Text(copy.paceWarning)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Palette.pink)
                    .padding(.top, 8)
            }
        }
    }
}
