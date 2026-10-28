import Combine
import SwiftUI

struct AccountDetailView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    var accountID: String
    @Environment(\.pageBack) private var pageBack

    var body: some View {
        let copy = store.copy
        if let account = store.book.accounts.first(where: { $0.id == accountID }) {
            let days = screen.windowDays
            let total = BookMath.accountTotal(account, entries: store.book.entries)
            let from = BookMath.windowStart(days: days)
            let prior = BookMath.accountNowAndPrior(account, entries: store.book.entries, priorISO: LedgerDay.adding(days: -1, to: from)).prior
            let delta = total - prior
            let today = LedgerDay.today()
            let windowEntries = store.book.entries.filter { $0.accountId == account.id && $0.date >= from && $0.date <= today }
            let inflow = windowEntries.filter { !$0.isOut }.reduce(0) { $0 + $1.amount }
            let outflow = windowEntries.filter(\.isOut).reduce(0) { $0 + $1.amount }
            let series = BookMath.windowSnapshot(accounts: [account], entries: store.book.entries, holdings: [], days: days).amounts
            FormPage(title: account.name, back: copy.back) {
                hero(copy, account: account, total: total, delta: delta, prior: prior, series: series)
                Button { screen.openAccountFeed(id: account.id) } label: {
                    flowStrip(copy, inflow: inflow, outflow: outflow)
                }
                .buttonStyle(.plain)
                if let cycle = BookMath.cardCycle(account, entries: store.book.entries) {
                    Button {
                        screen.openRange(account: account.id, from: cycle.start, to: cycle.end)
                    } label: {
                        PanelCard(title: copy.cardBill, titleSize: 15, card: true) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Palette.muted)
                        } content: {
                            MoneyText(value: cycle.spent, mark: store.book.mark, size: 28, color: Palette.down)
                            Text("\(copy.cardDueDay) \(copy.dayChip(cycle.due))")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Palette.muted)
                                .padding(.top, 6)
                            Text("\(copy.dayChip(cycle.start)) – \(copy.dayChip(cycle.end))")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Palette.faint)
                                .padding(.top, 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
                PillButton(title: copy.editAccount) { screen.open(.accountForm(id: account.id)) }
                PillButton(title: copy.accountDetailActivity, filled: false) { screen.openAccountFeed(id: account.id) }
            }
        } else {
            Color.white.onAppear { pageBack() }
        }
    }

    private func hero(_ copy: LedgerCopy, account: Account, total: Double, delta: Double, prior: Double, series: [Double]) -> some View {
        let up = delta >= 0
        return VStack(alignment: .leading, spacing: 0) {
            Text(copy.accountKind(account.kind))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.onDark)
            MoneyText(value: total, mark: store.book.mark, size: 36, color: .white)
                .padding(.top, 6)
            SegmentControl(labels: [copy.accountsWindow7, copy.accountsWindow30], index: screen.windowIndex, onDark: true) {
                screen.windowIndex = $0
            }
            .padding(.top, 14)
            TrendChart(amounts: series, fitDataRange: true)
                .id(screen.windowIndex)
                .padding(.top, 12)
            (
                Text(copy.accountPeriodDelta).foregroundColor(Palette.onDark)
                    + Text("  ")
                    + Text(LedgerMoney.text(delta, mark: store.book.mark, signed: true)).foregroundColor(.white)
                    + Text("  ")
                    + Text(BookMath.formatPercent(delta: delta, base: prior)).foregroundColor(up ? Palette.heroUp : Palette.pink)
            )
            .font(.system(size: 13, weight: .semibold))
            .padding(.top, 8)
        }
        .padding(EdgeInsets(top: 20, leading: 18, bottom: 18, trailing: 18))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.ink, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .plateShadow(opacity: 0.22, radius: 20, y: 18)
    }

    private func flowStrip(_ copy: LedgerCopy, inflow: Double, outflow: Double) -> some View {
        let net = inflow - outflow
        return HStack(spacing: 0) {
            statCell(copy.periodSpend, outflow, Palette.down)
            statCell(copy.periodIncome, inflow, Palette.up)
            statCell(copy.accountPeriodNet, net, net >= 0 ? Palette.up : Palette.down, signed: true)
        }
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Palette.line, lineWidth: 1))
    }

    private func statCell(_ title: String, _ value: Double, _ color: Color, signed: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.muted)
                .lineLimit(1)
            MoneyText(value: value, mark: store.book.mark, size: 15, signed: signed, color: color)
        }
        .frame(maxWidth: .infinity)
    }
}
