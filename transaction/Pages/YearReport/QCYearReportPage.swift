//
//  QCYearReportPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/28.
//

import SwiftUI

// The year: categories, months, the big spends, each account.
struct QCYearReportPage: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    @Environment(\.pageBack) private var pageBack
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var kind = "out"
    @State private var openCategory = ""
    @State private var showAllTops = false

    var body: some View {
        let copy = store.copy
        let kindName = copy.statsKindName(kind)
        let scoped = yearEntries()
        let picked = scoped.filter { matches($0) }
        let spend = summed(scoped.filter { $0.isOut && !$0.isTransfer })
        let income = summed(scoped.filter { !$0.isOut && !$0.isTransfer })
        let total = kind == "in" ? income : spend
        let columns = QCBookMath.yearColumns(QCBookMath.byScope(store.book.entries, screen.dashScope).filter { !$0.id.hasPrefix("sample-") }, year: year)
        let live = columns.filter { !upcoming($0.month) }
        let peak = live.map { columnAmount($0) }.max() ?? 0
        let average = live.isEmpty ? 0 : live.reduce(0) { $0 + columnAmount($1) } / Double(live.count)
        let peakMonth = live.max { lhs, rhs in
            let left = columnAmount(lhs)
            let right = columnAmount(rhs)
            if left == right { return lhs.month < rhs.month }
            return left < right
        }?.month
        let slices = QCYearReportGroup.buckets(picked, id: { $0.category }, name: { $0.category })
        let tops = picked.sorted { $0.amount > $1.amount }
        let shownTops = showAllTops ? Array(tops.prefix(30)) : Array(tops.prefix(5))
        let accounts = QCYearReportGroup.buckets(
            picked,
            id: { $0.accountId.isEmpty ? $0.accountName : $0.accountId },
            name: { entry in
                store.book.accounts.first { $0.id == entry.accountId }?.name ?? entry.accountName
            }
        )

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Button { pageBack() } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(QCPalette.ink)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(copy.back)
                Text("\(year) \(copy.yearReport)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 12)
                HStack(spacing: 0) {
                    yearStep("chevron.left", label: copy.yearPrev) { shiftYear(-1) }
                    Text(String(year))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(QCPalette.ink)
                    yearStep(
                        "chevron.right",
                        label: copy.yearNext,
                        enabled: year < Calendar.current.component(.year, from: Date())
                    ) { shiftYear(1) }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.white, in: Capsule())
                .overlay(Capsule().stroke(QCPalette.line, lineWidth: 1))
                .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(QCPalette.stage)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    kindPill(copy.statsOut, id: "out")
                    kindPill(copy.statsIn, id: "in")
                }
                hero(copy: copy, kindName: kindName, total: total, count: picked.count, balance: income - spend)
                QCYearReportClassify(
                    copy: copy,
                    mark: store.book.mark,
                    marks: store.book.categoryMarks,
                    slices: slices,
                    total: total,
                    openCategory: $openCategory,
                    titles: { category in
                        QCYearReportGroup.buckets(
                            yearEntries().filter { matches($0) && $0.category == category },
                            id: { $0.title },
                            name: { $0.title }
                        )
                    },
                    openSlice: { slice in
                        openFeed(month: nil, category: slice.name, title: nil, account: nil)
                    },
                    openTitle: { category, title in
                        openFeed(month: nil, category: category, title: title, account: nil)
                    },
                    onAdd: {
                        screen.statsKind = kind == "in" ? "in" : "out"
                        screen.openNewRecord(store: store)
                    }
                )
                QCYearReportCompare(
                    copy: copy,
                    mark: store.book.mark,
                    year: year,
                    kindName: kindName,
                    columns: columns,
                    peak: peak,
                    average: average,
                    peakMonth: peak > 0 ? peakMonth : nil,
                    amount: columnAmount,
                    upcoming: upcoming,
                    openMonth: { month in
                        openFeed(month: month, category: nil, title: nil, account: nil)
                    }
                )
                if !shownTops.isEmpty {
                    QCYearReportTops(
                        copy: copy,
                        mark: store.book.mark,
                        kindName: kindName,
                        rows: shownTops,
                        expanded: showAllTops,
                        more: tops.count > 5,
                        refunded: refunded,
                        toggle: { showAllTops.toggle() },
                        openEntry: { screen.open(.entry(id: $0)) }
                    )
                }
                if !accounts.isEmpty {
                    QCYearReportAccounts(
                        copy: copy,
                        mark: store.book.mark,
                        outgoing: kind != "in",
                        rows: accounts,
                        openAccount: { account in
                            openFeed(month: nil, category: nil, title: nil, account: account)
                        }
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
            .immediateScroll(place: "year")
        }
        }
        .background(QCPalette.stage)
    }

    private func hero(copy: QCLedgerCopy, kindName: String, total: Double, count: Int, balance: Double) -> some View {
        Button {
            openFeed(month: nil, category: nil, title: nil, account: nil)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(kindName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(QCPalette.muted)
                QCMoneyText(value: total, mark: store.book.mark, size: 36)
                Text(copy.yearCount(count))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(QCPalette.muted)
                HStack(spacing: 6) {
                    Text(copy.yearBalance)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(QCPalette.muted)
                    QCMoneyText(value: balance, mark: store.book.mark, size: 14, signed: true, color: QCPalette.ink)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(QCPalette.wash, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                Text(String(year))
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(QCPalette.pink.opacity(0.55))
                    .padding(.trailing, 12)
                    .padding(.bottom, 4)
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
    }

    private func yearStep(_ system: String, label: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(enabled ? QCPalette.ink : QCPalette.faint)
                .frame(width: 28, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func kindPill(_ title: String, id: String) -> some View {
        let on = kind == id
        return Button {
            kind = id
            openCategory = ""
            showAllTops = false
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(on ? QCPalette.ink : QCPalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .background(on ? QCPalette.pink : Color.white, in: Capsule())
        .overlay(Capsule().stroke(on ? Color.clear : QCPalette.line, lineWidth: 1))
    }

    private func yearEntries() -> [QCEntry] {
        let prefix = String(format: "%04d", year)
        return QCBookMath.byScope(store.book.entries, screen.dashScope).filter { !$0.id.hasPrefix("sample-") && $0.date.hasPrefix(prefix) }
    }

    private func matches(_ entry: QCEntry) -> Bool {
        if kind == "in" { return !entry.isOut && !entry.isTransfer }
        return entry.isOut && !entry.isTransfer
    }

    private func columnAmount(_ column: QCYearColumn) -> Double {
        kind == "in" ? column.income : column.spend
    }

    private func summed(_ entries: [QCEntry]) -> Double {
        QCLedgerMoney.cents(entries.reduce(0) { $0 + $1.amount })
    }

    private func refunded(_ id: String) -> Double {
        QCLedgerMoney.cents(store.book.entries.filter { $0.refundOf == id }.reduce(0) { $0 + $1.amount })
    }

    private func upcoming(_ month: Int) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let thisYear = calendar.component(.year, from: now)
        let thisMonth = calendar.component(.month, from: now)
        return year > thisYear || (year == thisYear && month > thisMonth)
    }

    private func shiftYear(_ delta: Int) {
        let cap = Calendar.current.component(.year, from: Date())
        year = min(cap, year + delta)
        openCategory = ""
        showAllTops = false
    }

    private func openFeed(month: Int?, category: String?, title: String?, account: String?) {
        let start: String
        let end: String
        if let month {
            let span = QCBookMath.monthSpan(year: year, month: month)
            start = span.start
            end = span.end
        } else {
            start = QCLedgerDay.iso(year: year, month: 1, day: 1)
            end = QCLedgerDay.iso(year: year, month: 12, day: 31)
        }
        screen.openStats(from: start, to: end, kind: kind, category: category, title: title)
        if let account {
            screen.accountId = account
        }
    }
}
