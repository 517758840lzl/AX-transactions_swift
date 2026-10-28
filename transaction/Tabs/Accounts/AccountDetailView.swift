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
                PanelCard {
                    Text(copy.accountKind(account.kind)).font(.system(size: 13)).foregroundStyle(Palette.muted)
                    MoneyText(value: total, mark: store.book.mark, size: 32)
                    HStack {
                        Text(copy.accountPeriodDelta).foregroundStyle(Palette.muted)
                        MoneyText(value: delta, mark: store.book.mark, size: 13, signed: true)
                        Text(BookMath.formatPercent(delta: delta, base: prior))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(delta >= 0 ? Palette.up : Palette.down)
                    }
                    .font(.system(size: 13))
                    Text("\(copy.accountPeriodNet) \(LedgerMoney.text(inflow - outflow, mark: store.book.mark, signed: true)) · \(copy.periodIncome) \(LedgerMoney.text(inflow, mark: store.book.mark)) · \(copy.periodSpend) \(LedgerMoney.text(outflow, mark: store.book.mark))")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.muted)
                    TrendChart(amounts: series)
                }
                PillButton(title: copy.editAccount) { screen.open(.accountForm(id: account.id)) }
                Button(copy.accountDetailActivity) { screen.openAccountFeed(id: account.id) }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
            }
        } else {
            Color.white.onAppear { pageBack() }
        }
    }
}
