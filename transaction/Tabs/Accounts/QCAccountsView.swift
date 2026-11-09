//
//  QCAccountsView.swift
//  transaction
//
//  Created by Lzl on 2026/10/20.
//

import SwiftUI

struct QCAccountsView: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    @Environment(\.pageBack) private var pageBack

    var body: some View {
        let copy = store.copy
        let own = store.book.accounts.filter { !$0.id.hasPrefix("sample-") }
        let days = QCBookMath.worthDays(screen.worthSpan, entries: store.book.entries)
        let priorISO = QCLedgerDay.adding(days: -1, to: QCBookMath.windowStart(days: days))
        let empty = own.isEmpty
        let showSample = !empty && !store.book.sampleCleared && store.book.accounts.contains { $0.id.hasPrefix("sample-") }

        VStack(alignment: .leading, spacing: 0) {
        QCSubpageHead(title: "\(copy.accounts) (\(own.count))", back: copy.back) { pageBack() }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(QCPalette.stage)
        QCPageScroll(place: "accounts", bottom: 16) {
            if empty {
                QCAccountIntro(copy: copy)
            } else {
                QCWorthSummary(store: store, screen: screen, accounts: own, opens: true)
                monthFlow(copy)
                mix(copy, priorISO: priorISO)
                ForEach(QCAccountKind.order, id: \.self) { kind in
                    if shows(kind.rawValue) {
                        accountGroup(kind, priorISO: priorISO, copy: copy)
                    }
                }
                archivedGroup(copy)
            }
            QCPillButton(title: copy.addAccount) {
                screen.open(.accountForm(id: nil, chooseKind: false))
            }
            if showSample {
                QCSampleBanner(title: copy.sampleBanner, actionTitle: copy.sampleClear) { store.clearSample() }
            }
        }
        }
    }

    private func shows(_ id: String) -> Bool {
        screen.accountFocus == nil || screen.accountFocus == id
    }

    private func ownAccounts() -> [QCAccount] {
        store.book.accounts.filter { !$0.id.hasPrefix("sample-") }
    }

    @ViewBuilder
    private func monthFlow(_ copy: QCLedgerCopy) -> some View {
        let prefix = QCLedgerDay.yearMonth(Date())
        let ownIds = Set(ownAccounts().map(\.id))
        let rows = store.book.entries.filter { $0.date.hasPrefix(prefix) && !$0.isTransfer && ownIds.contains($0.accountId) }
        if !rows.isEmpty {
            let spent = QCLedgerMoney.cents(rows.filter(\.isOut).reduce(0) { $0 + $1.amount })
            let income = QCLedgerMoney.cents(rows.filter { !$0.isOut }.reduce(0) { $0 + $1.amount })
            let accounts = ownAccounts().filter { account in
                !account.archived && rows.contains { $0.accountId == account.id }
            }
            VStack(alignment: .leading, spacing: 0) {
                Button { openMonth(account: nil) } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(copy.accountMonthFlow)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(QCPalette.ink)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(QCPalette.faint)
                        }
                        HStack(spacing: 8) {
                            Color.clear.frame(width: 28, height: 1)
                            flowStat(copy.periodSpend, spent, QCPalette.down, signed: false)
                            flowStat(copy.periodIncome, income, QCPalette.ink, signed: false)
                            flowStat(copy.accountPeriodNet, income - spent, QCPalette.ink, signed: true)
                        }
                    }
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                ForEach(accounts) { account in
                    let mine = rows.filter { $0.accountId == account.id }
                    let spent = QCLedgerMoney.cents(mine.filter(\.isOut).reduce(0) { $0 + $1.amount })
                    let income = QCLedgerMoney.cents(mine.filter { !$0.isOut }.reduce(0) { $0 + $1.amount })
                    Button { openMonth(account: account.id) } label: {
                        HStack(alignment: .center, spacing: 8) {
                            Text(String(account.name.prefix(1)))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(QCPalette.ink)
                                .frame(width: 28, height: 28)
                                .background(QCPalette.wash, in: Circle())
                            QCMoneyText(value: spent, mark: store.book.mark, size: 13, color: QCPalette.down)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            QCMoneyText(value: income, mark: store.book.mark, size: 13)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            QCMoneyText(value: income - spent, mark: store.book.mark, size: 13, signed: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minHeight: 56, alignment: .center)
                        .contentShape(Rectangle())
                        .overlay(alignment: .top) {
                            Rectangle().fill(QCPalette.line).frame(height: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(account.name)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 4)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
            .padding(.top, 12)
        }
    }

    private func flowStat(_ title: String, _ value: Double, _ color: Color, signed: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(QCPalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            QCMoneyText(value: value, mark: store.book.mark, size: 13, signed: signed, color: color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func openMonth(account: String?) {
        let now = Date()
        let calendar = Calendar.current
        let start = QCLedgerDay.iso(year: calendar.component(.year, from: now), month: calendar.component(.month, from: now), day: 1)
        if let account {
            screen.openRange(account: account, from: start, to: QCLedgerDay.today())
            return
        }
        screen.accountId = nil
        screen.txMode = .range
        screen.txFrom = start
        screen.txTo = QCLedgerDay.today()
        screen.category = nil
        screen.feedKind = ""
        screen.status = "all"
        screen.txDirection = "all"
        screen.search = ""
        screen.showCalendar = false
        screen.txUnscoped = true
        screen.reveal(tab: 1)
    }

    private func mix(_ copy: QCLedgerCopy, priorISO: String) -> some View {
        let rows = mixRows(priorISO: priorISO, copy: copy)
        let scale = rows.map { abs($0.amount) }.max() ?? 1
        return Group {
            if rows.count >= 2 {
                VStack(alignment: .leading, spacing: 0) {
                    Text(copy.accountMix)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(QCPalette.muted)
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
                                            .foregroundStyle(QCPalette.ink)
                                        Spacer(minLength: 8)
                                        QCMoneyText(value: row.amount, mark: store.book.mark, size: 15)
                                    }
                                    QCPortionBar(
                                        fraction: scale > 0 ? abs(row.amount) / scale : 0,
                                        tint: screen.accountFocus == row.id ? QCPalette.ink : QCPalette.pink,
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
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
                    .padding(.top, 8)
                }
            }
        }
    }

    private func mixRows(priorISO: String, copy: QCLedgerCopy) -> [QCMixSlice] {
        var rows: [QCMixSlice] = []
        for kind in QCAccountKind.order {
            let accounts = ownAccounts().filter { $0.kind == kind && !$0.archived }
            if accounts.isEmpty { continue }
            let total = accounts.reduce(0) { sum, account in
                sum + QCBookMath.accountNowAndPrior(account, entries: store.book.entries, priorISO: priorISO).now
            }
            rows.append(QCMixSlice(id: kind.rawValue, title: copy.accountKind(kind), amount: total))
        }
        return rows
    }

    @ViewBuilder
    private func accountGroup(_ kind: QCAccountKind, priorISO: String, copy: QCLedgerCopy) -> some View {
        let accounts = ownAccounts().filter { $0.kind == kind && !$0.archived }
        if !accounts.isEmpty {
            let toneBase = QCAccountKind.order.firstIndex(of: kind) ?? 0
            let rows = accounts.map { account -> (QCAccount, Double, Double) in
                let pair = QCBookMath.accountNowAndPrior(account, entries: store.book.entries, priorISO: priorISO)
                return (account, pair.now, pair.prior)
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(copy.accountKind(kind))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(QCPalette.muted)
                    Spacer()
                    QCMoneyText(value: rows.reduce(0) { $0 + $1.1 }, mark: store.book.mark, size: 13)
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
                            detail: QCBookMath.formatPercent(delta: delta, base: row.2),
                            detailColor: delta >= 0 ? QCPalette.up : QCPalette.down
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func archivedGroup(_ copy: QCLedgerCopy) -> some View {
        let accounts = ownAccounts().filter(\.archived)
        if !accounts.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text(copy.archivedTitle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(QCPalette.muted)
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                    Button {
                        screen.open(.account(id: account.id))
                    } label: {
                        ledgerLine(
                            name: account.name,
                            meta: copy.accountKind(account.kind),
                            tone: index,
                            value: QCBookMath.accountTotal(account, entries: store.book.entries),
                            detail: "",
                            detailColor: QCPalette.muted
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
    }

    private func ledgerLine(name: String, meta: String, tone: Int, value: Double, detail: String? = nil, detailColor: Color = QCPalette.muted, signed: Double? = nil) -> some View {
        let initial = name.isEmpty ? "?" : String(name.prefix(1))
        return HStack(spacing: 12) {
            Text(initial)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(QCPalette.ink)
                .frame(width: 40, height: 40)
                .background(QCPalette.slice(tone).opacity(0.2), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 16, weight: .bold)).foregroundStyle(QCPalette.ink).lineLimit(1)
                Text(meta).font(.system(size: 12)).foregroundStyle(QCPalette.muted).lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                QCMoneyText(value: value, mark: store.book.mark, size: 16)
                if let signed {
                    QCMoneyText(value: signed, mark: store.book.mark, size: 13, signed: true)
                } else if let detail {
                    Text(detail).font(.system(size: 12, weight: .bold)).foregroundStyle(detailColor)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
        .contentShape(Rectangle())
        .plateShadow(opacity: 0.04, radius: 10, y: 8)
        .padding(.top, 8)
    }
}

private struct QCMixSlice: Identifiable {
    var id: String
    var title: String
    var amount: Double
}

private struct QCAccountIntro: View {
    var copy: QCLedgerCopy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "banknote")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(QCPalette.ink)
                    .frame(width: 36, height: 36)
                    .background(Color.white, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(copy.accountIntroTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(QCPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(copy.accountIntroBody)
                        .font(.system(size: 13))
                        .foregroundStyle(QCPalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(QCPalette.pink.opacity(0.55), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            introRow("chart.bar.fill", copy.accountIntroSumTitle, copy.accountIntroSumBody)
            introRow("lock.fill", copy.accountIntroLocalTitle, copy.accountIntroLocalBody)
            introRow("creditcard", copy.accountIntroNameTitle, copy.accountIntroNameBody)
        }
        .padding(.top, 16)
    }

    private func introRow(_ symbol: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(QCPalette.ink)
                .frame(width: 36, height: 36)
                .background(QCPalette.wash, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
                Text(body)
                    .font(.system(size: 14))
                    .foregroundStyle(QCPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
    }
}
