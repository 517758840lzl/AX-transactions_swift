//
//  AccountsView.swift
//  transaction
//
//  Created by Lzl on 2026/10/20.
//

import Combine
import SwiftUI

struct AccountsView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen

    var body: some View {
        let copy = store.copy
        let days = BookMath.worthDays(screen.worthSpan, entries: store.book.entries)
        let priorISO = LedgerDay.adding(days: -1, to: BookMath.windowStart(days: days))
        let empty = store.book.accounts.isEmpty
        let showSample = !store.book.sampleCleared && store.book.accounts.contains { $0.id.hasPrefix("sample-") }

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
                WorthSummary(store: store, screen: screen, opens: true)
                monthFlow(copy)
                mix(copy, priorISO: priorISO)
                ForEach(AccountKind.order, id: \.self) { kind in
                    if shows(kind.rawValue) {
                        accountGroup(kind, priorISO: priorISO, copy: copy)
                    }
                }
                archivedGroup(copy)
            }
            if store.book.accounts.count >= 2 {
                PillButton(title: copy.transfer, filled: false) { screen.open(.transfer) }
            }
            PillButton(title: copy.addAccount) { screen.open(.accountForm(id: nil)) }
            if showSample {
                SampleBanner(title: copy.sampleBanner, actionTitle: copy.sampleClear) { store.clearSample() }
            }
        }
    }

    private func shows(_ id: String) -> Bool {
        screen.accountFocus == nil || screen.accountFocus == id
    }

    @ViewBuilder
    private func monthFlow(_ copy: LedgerCopy) -> some View {
        let prefix = LedgerDay.yearMonth(Date())
        let rows = store.book.entries.filter { $0.date.hasPrefix(prefix) }
        if !rows.isEmpty {
            let spent = LedgerMoney.cents(rows.filter(\.isOut).reduce(0) { $0 + $1.amount })
            let income = LedgerMoney.cents(rows.filter { !$0.isOut }.reduce(0) { $0 + $1.amount })
            let accounts = store.book.accounts.filter { account in
                !account.archived && rows.contains { $0.accountId == account.id }
            }
            VStack(alignment: .leading, spacing: 0) {
                Button { openMonth(account: nil) } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(copy.accountMonthFlow)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Palette.ink)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Palette.faint)
                        }
                        HStack(spacing: 8) {
                            Color.clear.frame(width: 28, height: 1)
                            flowStat(copy.periodSpend, spent, Palette.down, signed: false)
                            flowStat(copy.periodIncome, income, Palette.ink, signed: false)
                            flowStat(copy.accountPeriodNet, income - spent, Palette.ink, signed: true)
                        }
                    }
                    .padding(.bottom, 12)
                }
                .buttonStyle(.plain)
                ForEach(accounts) { account in
                    let mine = rows.filter { $0.accountId == account.id }
                    let spent = LedgerMoney.cents(mine.filter(\.isOut).reduce(0) { $0 + $1.amount })
                    let income = LedgerMoney.cents(mine.filter { !$0.isOut }.reduce(0) { $0 + $1.amount })
                    Button { openMonth(account: account.id) } label: {
                        HStack(spacing: 8) {
                            Text(String(account.name.prefix(1)))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Palette.ink)
                                .frame(width: 28, height: 28)
                                .background(Palette.wash, in: Circle())
                            MoneyText(value: spent, mark: store.book.mark, size: 13, color: Palette.down)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            MoneyText(value: income, mark: store.book.mark, size: 13)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            MoneyText(value: income - spent, mark: store.book.mark, size: 13, signed: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 8)
                        .overlay(alignment: .top) {
                            Rectangle().fill(Palette.line).frame(height: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(account.name)
                }
            }
            .padding(14)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Palette.line, lineWidth: 1))
            .padding(.top, 12)
        }
    }

    private func flowStat(_ title: String, _ value: Double, _ color: Color, signed: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Palette.muted)
            MoneyText(value: value, mark: store.book.mark, size: 13, signed: signed, color: color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func openMonth(account: String?) {
        let now = Date()
        let calendar = Calendar.current
        let start = LedgerDay.iso(year: calendar.component(.year, from: now), month: calendar.component(.month, from: now), day: 1)
        if let account {
            screen.openRange(account: account, from: start, to: LedgerDay.today())
            return
        }
        screen.accountId = nil
        screen.txMode = .range
        screen.txFrom = start
        screen.txTo = LedgerDay.today()
        screen.category = nil
        screen.feedKind = ""
        screen.status = "all"
        screen.txDirection = "all"
        screen.search = ""
        screen.showCalendar = false
        screen.txUnscoped = true
        screen.reveal(tab: 1)
    }

    private func mix(_ copy: LedgerCopy, priorISO: String) -> some View {
        let rows = mixRows(priorISO: priorISO, copy: copy)
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
                                    PortionBar(
                                        fraction: scale > 0 ? abs(row.amount) / scale : 0,
                                        tint: screen.accountFocus == row.id ? Palette.ink : Palette.pink,
                                        height: 6
                                    )
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

    private func mixRows(priorISO: String, copy: LedgerCopy) -> [MixSlice] {
        var rows: [MixSlice] = []
        for kind in AccountKind.order {
            let accounts = store.book.accounts.filter { $0.kind == kind && !$0.archived }
            if accounts.isEmpty { continue }
            let total = accounts.reduce(0) { sum, account in
                sum + BookMath.accountNowAndPrior(account, entries: store.book.entries, priorISO: priorISO).now
            }
            rows.append(MixSlice(id: kind.rawValue, title: copy.accountKind(kind), amount: total))
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
