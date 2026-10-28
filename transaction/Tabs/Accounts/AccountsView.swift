import Combine
import SwiftUI

struct AccountsView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen

    var body: some View {
        let copy = store.copy
        let days = screen.windowDays
        let snapshot = BookMath.windowSnapshot(
            accounts: store.book.accounts,
            entries: store.book.entries,
            holdings: store.book.holdings,
            days: days
        )
        let priorISO = LedgerDay.adding(days: -1, to: BookMath.windowStart(days: days))
        let stocks = store.book.holdings.filter { $0.kind == .stock || $0.kind == .etf }
        let funds = store.book.holdings.filter { $0.kind == .fund }
        let empty = store.book.accounts.isEmpty && store.book.holdings.isEmpty
        let showSample = !store.book.sampleCleared && (
            store.book.accounts.contains { $0.id.hasPrefix("sample-") } || store.book.holdings.contains { $0.id.hasPrefix("sample-") }
        )

        PageScroll(bottom: 16) {
            HStack {
                Text(copy.accounts).font(.system(size: 26, weight: .bold)).tracking(-0.4).foregroundStyle(Palette.ink)
                Spacer()
                Text(copy.accountCountText(store.book.accounts.count))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.muted)
            }
            if empty {
                Text(copy.accountsEmpty).font(.system(size: 15)).foregroundStyle(Palette.muted).padding(.top, 24)
            } else {
                hero(copy, snapshot: snapshot)
                mix(copy, priorISO: priorISO, stocks: stocks, funds: funds)
                ForEach(AccountKind.order, id: \.self) { kind in
                    if shows(kind.rawValue) {
                        accountGroup(kind, priorISO: priorISO, copy: copy)
                    }
                }
                if shows("stock") {
                    holdingGroup(copy.holdingsStock, stocks, toneOffset: 2, copy: copy)
                }
                if shows("fund") {
                    holdingGroup(copy.holdingsFund, funds, toneOffset: 5, copy: copy)
                }
                archivedGroup(copy)
            }
            if store.book.accounts.count >= 2 {
                PillButton(title: copy.transfer, filled: false) { screen.open(.transfer) }
            }
            PillButton(title: copy.addAccount) { screen.open(.accountForm(id: nil)) }
            PillButton(title: copy.addHolding, filled: false) { screen.open(.holdingForm(id: nil)) }
            if showSample {
                SampleBanner(title: copy.sampleBanner, actionTitle: copy.sampleClear) { store.clearSample() }
            }
        }
    }

    private func hero(_ copy: LedgerCopy, snapshot: WindowSnapshot) -> some View {
        let up = snapshot.delta >= 0
        return VStack(alignment: .leading, spacing: 0) {
            Text(copy.netAssets)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.onDark)
            MoneyText(value: snapshot.netWorth, mark: store.book.mark, size: 36, color: .white)
                .padding(.top, 6)
            if snapshot.holdingsTotal > 0 {
                (
                    Text(copy.accountBalance).foregroundColor(Palette.onDarkSoft)
                        + Text(" ")
                        + Text(LedgerMoney.text(snapshot.cashBalance, mark: store.book.mark)).foregroundColor(Palette.onDarkSoft)
                        + Text(" · ").foregroundColor(Palette.onDarkSoft)
                        + Text(copy.holdingMarketValue).foregroundColor(Palette.onDarkSoft)
                        + Text(" ")
                        + Text(LedgerMoney.text(snapshot.holdingsTotal, mark: store.book.mark)).foregroundColor(Palette.onDarkSoft)
                )
                .font(.system(size: 13, weight: .semibold))
                .padding(.top, 10)
            }
            SegmentControl(labels: [copy.accountsWindow7, copy.accountsWindow30], index: screen.windowIndex, onDark: true) {
                screen.windowIndex = $0
            }
            .padding(.top, 14)
            TrendChart(amounts: snapshot.amounts, fitDataRange: true)
                .id(screen.windowIndex)
                .padding(.top, 12)
            (
                Text(copy.accountPeriodDelta).foregroundColor(Palette.onDark)
                    + Text("  ")
                    + Text(LedgerMoney.text(snapshot.delta, mark: store.book.mark, signed: true)).foregroundColor(.white)
                    + Text("  ")
                    + Text(BookMath.formatPercent(delta: snapshot.delta, base: snapshot.prior)).foregroundColor(up ? Palette.heroUp : Palette.pink)
            )
            .font(.system(size: 13, weight: .semibold))
            .padding(.top, 8)
        }
        .padding(EdgeInsets(top: 20, leading: 18, bottom: 18, trailing: 18))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.ink, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .plateShadow(opacity: 0.22, radius: 20, y: 18)
        .padding(.top, 2)
        .id(screen.windowIndex)
    }

    private func shows(_ id: String) -> Bool {
        screen.accountFocus == nil || screen.accountFocus == id
    }

    private func mix(_ copy: LedgerCopy, priorISO: String, stocks: [Holding], funds: [Holding]) -> some View {
        let rows = mixRows(priorISO: priorISO, stocks: stocks, funds: funds, copy: copy)
        let scale = rows.map { abs($0.amount) }.max() ?? 1
        return Group {
            if rows.count >= 2 {
                VStack(alignment: .leading, spacing: 0) {
                    Text(copy.accountMix)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Palette.muted)
                        .padding(.top, 8)
                    VStack(spacing: 0) {
                        ForEach(rows) { row in
                            Button {
                                screen.accountFocus = screen.accountFocus == row.id ? nil : row.id
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(row.title)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(Palette.ink)
                                        Spacer(minLength: 8)
                                        MoneyText(value: row.amount, mark: store.book.mark, size: 15)
                                    }
                                    GeometryReader { proxy in
                                        let width = scale > 0 ? proxy.size.width * min(abs(row.amount) / scale, 1) : 0
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Palette.wash)
                                            Capsule().fill(screen.accountFocus == row.id ? Palette.ink : Palette.pink).frame(width: max(width, 4))
                                        }
                                    }
                                    .frame(height: 6)
                                }
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Palette.line, lineWidth: 1))
                    .padding(.top, 8)
                }
            }
        }
    }

    private func mixRows(priorISO: String, stocks: [Holding], funds: [Holding], copy: LedgerCopy) -> [MixSlice] {
        var rows: [MixSlice] = []
        for kind in AccountKind.order {
            let accounts = store.book.accounts.filter { $0.kind == kind && !$0.archived }
            if accounts.isEmpty { continue }
            let total = accounts.reduce(0) { sum, account in
                sum + BookMath.accountNowAndPrior(account, entries: store.book.entries, priorISO: priorISO).now
            }
            rows.append(MixSlice(id: kind.rawValue, title: copy.accountKind(kind), amount: total))
        }
        if !stocks.isEmpty {
            rows.append(MixSlice(id: "stock", title: copy.holdingsStock, amount: stocks.reduce(0) { $0 + BookMath.holdingMarketValue($1) }))
        }
        if !funds.isEmpty {
            rows.append(MixSlice(id: "fund", title: copy.holdingsFund, amount: funds.reduce(0) { $0 + BookMath.holdingMarketValue($1) }))
        }
        return rows
    }

    @ViewBuilder
    private func accountGroup(_ kind: AccountKind, priorISO: String, copy: LedgerCopy) -> some View {
        let accounts = store.book.accounts.filter { $0.kind == kind && !$0.archived }
        if !accounts.isEmpty {
            let toneBase = AccountKind.order.firstIndex(of: kind) ?? 0
            let rows = accounts.map { account -> (Account, Double, Double) in
                let pair = BookMath.accountNowAndPrior(account, entries: store.book.entries, priorISO: priorISO)
                return (account, pair.now, pair.prior)
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(copy.accountKind(kind))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Palette.muted)
                    Spacer()
                    MoneyText(value: rows.reduce(0) { $0 + $1.1 }, mark: store.book.mark, size: 13)
                }
                ForEach(Array(rows.enumerated()), id: \.element.0.id) { index, row in
                    let delta = row.1 - row.2
                    Button {
                        screen.open(.account(id: row.0.id))
                    } label: {
                        ledgerLine(
                            name: row.0.name,
                            meta: row.0.countsInWorth ? copy.accountKind(row.0.kind) : "\(copy.accountKind(row.0.kind)) · \(copy.worthLeftOut)",
                            tone: index + toneBase,
                            value: row.1,
                            detail: BookMath.formatPercent(delta: delta, base: row.2),
                            detailColor: delta >= 0 ? Palette.up : Palette.down
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func archivedGroup(_ copy: LedgerCopy) -> some View {
        let accounts = store.book.accounts.filter(\.archived)
        if !accounts.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text(copy.archivedTitle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.muted)
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                    Button {
                        screen.open(.account(id: account.id))
                    } label: {
                        ledgerLine(
                            name: account.name,
                            meta: copy.accountKind(account.kind),
                            tone: index,
                            value: BookMath.accountTotal(account, entries: store.book.entries),
                            detail: "",
                            detailColor: Palette.muted
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func holdingGroup(_ title: String, _ holdings: [Holding], toneOffset: Int, copy: LedgerCopy) -> some View {
        if !holdings.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Palette.muted)
                    Spacer()
                    MoneyText(value: holdings.reduce(0) { $0 + BookMath.holdingMarketValue($1) }, mark: store.book.mark, size: 13)
                }
                ForEach(Array(holdings.enumerated()), id: \.element.id) { index, holding in
                    Button {
                        screen.open(.holding(id: holding.id))
                    } label: {
                        let places = holding.kind == .fund ? 2 : 0
                        let qty = "\(LedgerMoney.fixed(holding.qty, fraction: places)) \(copy.shareUnit(holding.kind))"
                        ledgerLine(
                            name: holding.name,
                            meta: "\(holding.code) · \(copy.holdingKind(holding.kind)) · \(qty)",
                            tone: index + toneOffset,
                            value: BookMath.holdingMarketValue(holding),
                            signed: BookMath.holdingPnl(holding)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
    }

    private func ledgerLine(name: String, meta: String, tone: Int, value: Double, detail: String? = nil, detailColor: Color = Palette.muted, signed: Double? = nil) -> some View {
        let initial = name.isEmpty ? "?" : String(name.prefix(1))
        return HStack(spacing: 12) {
            Text(initial)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.ink)
                .frame(width: 40, height: 40)
                .background(Palette.slice(tone).opacity(0.2), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 16, weight: .bold)).foregroundStyle(Palette.ink).lineLimit(1)
                Text(meta).font(.system(size: 12)).foregroundStyle(Palette.muted).lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                MoneyText(value: value, mark: store.book.mark, size: 16)
                if let signed {
                    MoneyText(value: signed, mark: store.book.mark, size: 13, signed: true)
                } else if let detail {
                    Text(detail).font(.system(size: 12, weight: .bold)).foregroundStyle(detailColor)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Palette.line, lineWidth: 1))
        .plateShadow(opacity: 0.04, radius: 10, y: 8)
        .padding(.top, 8)
    }
}

private struct MixSlice: Identifiable {
    var id: String
    var title: String
    var amount: Double
}
