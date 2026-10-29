//
//  TransactionsView.swift
//  transaction
//
//  Created by Lzl on 2026/10/13.
//

import Combine
import SwiftUI
import UIKit

struct TransactionsView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    @State private var filterWidth: CGFloat = 320

    var body: some View {
        let copy = store.copy
        let span = inSpan()
        let spend = span.filter { $0.isOut && !$0.isTransfer }.reduce(0) { $0 + $1.amount }
        let income = span.filter { !$0.isOut && !$0.isTransfer }.reduce(0) { $0 + $1.amount }
        let period = directed(span)
        let listed: [Entry] = {
            guard screen.showCalendar, let day = screen.calendarDay else { return period }
            return period.filter { $0.date == day }
        }()
        let chartSpan = directed(inSpan(keepingCategory: false))
        let parts = BookMath.categoryParts(chartSpan, caps: [:]).sorted { $0.amount > $1.amount }
        let total = parts.reduce(0) { $0 + $1.amount }
        let previous = BookMath.prevMonthOutByCategory(store.book.entries)
        let spendByDay = Dictionary(grouping: period.filter { $0.isOut && !$0.isTransfer }, by: \.date).mapValues { $0.reduce(0) { $0 + $1.amount } }
        let showSample = !store.book.sampleCleared && store.book.entries.contains { $0.id.hasPrefix("sample-") }
        let accountName = store.book.accounts.first { $0.id == screen.accountId }?.name
        let listTitle = screen.showCalendar ? copy.dayChip(screen.calendarDay ?? LedgerDay.today()) : copy.periodChip(mode: screen.txMode, from: screen.txFrom, to: screen.txTo)

        PageScroll(bottom: 88) {
            HStack {
                Text(copy.transactions).font(.system(size: 26, weight: .bold)).tracking(-0.4).foregroundStyle(Palette.ink)
                Spacer()
                Button(copy.periodChip(mode: screen.txMode, from: screen.txFrom, to: screen.txTo)) {
                    screen.open(.filter(which: "transactions"))
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background(Color.white, in: Capsule())
                .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
            }
            flowStrip(copy, spend: spend, income: income)
            toolbar(copy, accountName: accountName)
            VStack(alignment: .leading, spacing: 12) {
                if !parts.isEmpty {
                    PanelCard(
                        title: "\(copy.category) · \(copy.periodChip(mode: screen.txMode, from: screen.txFrom, to: screen.txTo))",
                        titleSize: 15,
                        card: true
                    ) {
                        HStack(alignment: .top, spacing: 12) {
                            SpendDonut(parts: parts, total: total, mark: store.book.mark, caption: copy.periodSpend, active: screen.category) { name in
                                screen.category = screen.category == name ? nil : name
                            }
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(parts) { part in
                                    rankRow(part, total: total, previous: previous[part.name] ?? 0, copy: copy)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                if screen.showCalendar {
                    CalendarMonth(copy: copy, spend: spendByDay, selected: screen.calendarDay ?? LedgerDay.today()) { day in
                        screen.calendarDay = day
                    }
                    .transition(.opacity)
                }
                PanelCard(title: listTitle) {
                    if listed.isEmpty {
                        Text(copy.txEmpty).font(.system(size: 13)).foregroundStyle(Palette.muted)
                    } else {
                        rows(listed, copy: copy)
                    }
                }
                if showSample {
                    SampleBanner(title: copy.sampleBanner, actionTitle: copy.sampleClear) { store.clearSample() }
                }
            }
            .animation(LedgerScreen.fold, value: screen.showCalendar)
        }
    }

    private func toolbar(_ copy: LedgerCopy, accountName: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField(copy.searchPlaceholder, text: $screen.search)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .font(.system(size: 15))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Palette.line, lineWidth: 1))
            SegmentControl(labels: [copy.txViewList, copy.txViewCalendar], index: screen.showCalendar ? 1 : 0) { index in
                screen.showCalendar = index == 1
                if index == 1, screen.calendarDay == nil { screen.calendarDay = LedgerDay.today() }
            }
            filterRow(copy, accountName: accountName)
        }
        .padding(12)
        .background(Palette.neutral, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Palette.line, lineWidth: 1))
    }

    private func rows(_ listed: [Entry], copy: LedgerCopy) -> some View {
        let groups = dayGroups(listed)
        let flat = groups.flatMap(\.entries)
        let firstOfDay = Dictionary(uniqueKeysWithValues: groups.map { ($0.day, $0.entries.first?.id) })
        return LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(Array(flat.enumerated()), id: \.element.id) { index, entry in
                if !screen.showCalendar, firstOfDay[entry.date] == entry.id {
                    dayHead(entry.date, entries: groups.first { $0.day == entry.date }?.entries ?? [], copy: copy)
                        .padding(.top, index == 0 ? 0 : 10)
                }
                TxRow(
                    entry: entry,
                    mark: store.book.mark,
                    copy: copy,
                    showTopBorder: index > 0,
                    onOpen: { screen.open(.entry(id: entry.id)) },
                    onToggle: { store.toggleChecked(entry.id) }
                )
            }
        }
    }

    private func rankRow(_ part: CategoryPart, total: Double, previous: Double, copy: LedgerCopy) -> some View {
        let active = screen.category == part.name
        return Button {
            screen.category = active ? nil : part.name
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    Circle().fill(Palette.slice(part.colorIndex)).frame(width: 8, height: 8)
                    Text(part.name)
                        .font(.system(size: 13, weight: active ? .heavy : .semibold))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 2) {
                        MoneyText(value: part.amount, mark: store.book.mark, size: 13)
                        rankLabel(part.amount, previous: previous, copy: copy)
                    }
                }
                PortionBar(
                    fraction: total > 0 ? part.amount / total : 0,
                    tint: Palette.slice(part.colorIndex),
                    height: 4
                )
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func flowStrip(_ copy: LedgerCopy, spend: Double, income: Double) -> some View {
        let balance = income - spend
        return HStack(spacing: 0) {
            flowCell(copy.periodSpend, spend, active: screen.txDirection == "out", color: Palette.down) {
                screen.txDirection = screen.txDirection == "out" ? "all" : "out"
            }
            flowCell(copy.periodIncome, income, active: screen.txDirection == "in", color: Palette.up) {
                screen.txDirection = screen.txDirection == "in" ? "all" : "in"
            }
            flowCell(copy.periodBalance, balance, active: screen.txDirection == "all", color: balance >= 0 ? Palette.up : Palette.down, signed: true) {
                screen.txDirection = "all"
            }
        }
        .padding(8)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Palette.line, lineWidth: 1))
    }

    private func flowCell(_ title: String, _ value: Double, active: Bool, color: Color, signed: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.muted)
                MoneyText(value: value, mark: store.book.mark, size: 16, signed: signed, color: color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(active ? Palette.wash : Color.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(active ? Palette.line : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func dayHead(_ day: String, entries: [Entry], copy: LedgerCopy) -> some View {
        let out = entries.filter { $0.isOut && !$0.isTransfer }.reduce(0) { $0 + $1.amount }
        let income = entries.filter { !$0.isOut && !$0.isTransfer }.reduce(0) { $0 + $1.amount }
        return Button {
            screen.calendarDay = day
            screen.showCalendar = true
        } label: {
            HStack(spacing: 8) {
                Text(copy.dayChip(day))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 8)
                if out > 0 {
                    MoneyText(value: out, mark: store.book.mark, size: 12, color: Palette.down)
                }
                if income > 0 {
                    MoneyText(value: income, mark: store.book.mark, size: 12, color: Palette.up)
                }
            }
            .padding(.bottom, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func inSpan(keepingCategory: Bool = true) -> [Entry] {
        let bounds = LedgerDay.bounds(mode: screen.txMode, from: screen.txFrom, to: screen.txTo)
        let query = screen.search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let pool = screen.txUnscoped ? store.book.entries : BookMath.byScope(store.book.entries, screen.txScope)
        return BookMath.inPeriod(pool, bounds).filter { entry in
            if screen.feedKind == "out", entry.isTransfer || !entry.isOut { return false }
            if screen.feedKind == "in", entry.isTransfer || entry.isOut { return false }
            if screen.feedKind == "other", !entry.isTransfer || !entry.isOut { return false }
            if keepingCategory, let category = screen.category, entry.category != category { return false }
            if let accountId = screen.accountId, entry.accountId != accountId { return false }
            if screen.status == "open", entry.checked { return false }
            if screen.status == "done", !entry.checked { return false }
            if query.isEmpty { return true }
            let hay = "\(entry.title) \(entry.category) \(entry.accountName)".lowercased()
            return hay.contains(query)
        }
    }

    private func directed(_ entries: [Entry]) -> [Entry] {
        switch screen.txDirection {
        case "out": return entries.filter(\.isOut)
        case "in": return entries.filter { !$0.isOut }
        default: return entries
        }
    }

    private func filterRow(_ copy: LedgerCopy, accountName: String?) -> some View {
        var items: [(title: String, value: String)] = [
            (copy.filterAll, "all"),
            (copy.filterOpen, "open"),
            (copy.filterDone, "done"),
        ]
        if !screen.feedKind.isEmpty {
            items.append(("\(copy.statsKindName(screen.feedKind)) ×", "feed"))
        }
        if let name = screen.category {
            items.append(("\(copy.category) \(name) ×", "category"))
        }
        if let accountName, screen.accountId != nil {
            items.append(("\(copy.filterAccount) \(accountName) ×", "account"))
        }
        let rows = wrappedFilters(items, width: filterWidth)
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(spacing: 8) {
                    ForEach(rows[index], id: \.value) { item in
                        statusChip(item.title, item.value)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GeometryReader { proxy in
            Color.clear.preference(key: FilterWidthKey.self, value: proxy.size.width)
        })
        .onPreferenceChange(FilterWidthKey.self) { next in
            if abs(next - filterWidth) > 0.5 { filterWidth = next }
        }
    }

    private func wrappedFilters(_ items: [(title: String, value: String)], width: CGFloat) -> [[(title: String, value: String)]] {
        var rows: [[(title: String, value: String)]] = []
        var row: [(title: String, value: String)] = []
        var used: CGFloat = 0
        let limit = max(width, 1)
        let font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        for item in items {
            let chip = ceil((item.title as NSString).size(withAttributes: [.font: font]).width) + 24
            let next = row.isEmpty ? chip : used + 8 + chip
            if !row.isEmpty, next > limit {
                rows.append(row)
                row = [item]
                used = chip
            } else {
                row.append(item)
                used = next
            }
        }
        if !row.isEmpty { rows.append(row) }
        return rows
    }

    private func statusChip(_ title: String, _ value: String) -> some View {
        let selected = value == "category" || value == "account" || value == "feed" || screen.status == value
        return Button(title) {
            if value == "feed" { screen.feedKind = "" }
            else if value == "category" { screen.category = nil }
            else if value == "account" { screen.accountId = nil }
            else { screen.status = value }
        }
        .font(.system(size: 13, weight: .semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .foregroundStyle(selected ? Palette.ink : Palette.muted)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .background(selected ? Palette.pink : Color.white, in: Capsule())
        .overlay(Capsule().stroke(selected ? Palette.pink : Palette.line, lineWidth: 1))
    }

    private func rankLabel(_ amount: Double, previous: Double, copy: LedgerCopy) -> some View {
        let label: String
        let color: Color
        if amount > previous {
            label = copy.rankUp
            color = Palette.down
        } else if amount < previous {
            label = copy.rankDown
            color = Palette.up
        } else {
            label = copy.rankFlat
            color = Palette.muted
        }
        return Text(label).font(.system(size: 11, weight: .bold)).foregroundStyle(color)
    }

    private func dayGroups(_ entries: [Entry]) -> [(day: String, entries: [Entry])] {
        var grouped: [String: [Entry]] = [:]
        for entry in entries {
            grouped[entry.date, default: []].append(entry)
        }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0] ?? []) }
    }
}

private struct FilterWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
