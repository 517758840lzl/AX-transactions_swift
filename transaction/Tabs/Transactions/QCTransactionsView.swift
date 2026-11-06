//
//  QCTransactionsView.swift
//  transaction
//
//  Created by Lzl on 2026/10/13.
//

import SwiftUI
import UIKit

struct QCTransactionsView: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    @State private var filterWidth: CGFloat = 320
    @State private var searchOpen = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        let copy = store.copy
        let span = inSpan()
        let spend = span.filter { $0.isOut && !$0.isTransfer }.reduce(0) { $0 + $1.amount }
        let income = span.filter { !$0.isOut && !$0.isTransfer }.reduce(0) { $0 + $1.amount }
        let period = directed(span)
        let listed: [QCEntry] = {
            guard screen.showCalendar, let day = screen.calendarDay else { return period }
            return period.filter { $0.date == day }
        }()
        let chartSpan = directed(inSpan(keepingCategory: false))
        let parts = QCBookMath.categoryParts(chartSpan, caps: [:]).sorted { $0.amount > $1.amount }
        let total = parts.reduce(0) { $0 + $1.amount }
        let previous = QCBookMath.prevMonthOutByCategory(store.book.entries.filter { !$0.id.hasPrefix("sample-") })
        let spendByDay = Dictionary(grouping: period.filter { $0.isOut && !$0.isTransfer }, by: \.date).mapValues { $0.reduce(0) { $0 + $1.amount } }
        let accountName = store.book.accounts.first { $0.id == screen.accountId }?.name
        let listTitle = screen.showCalendar ? copy.dayChip(screen.calendarDay ?? QCLedgerDay.today()) : heading(copy)

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(copy.transactions)
                    .font(.system(size: 26, weight: .bold))
                    .tracking(-0.4)
                    .foregroundStyle(QCPalette.ink)
                    .lineLimit(1)
                    .layoutPriority(1)
                Spacer(minLength: 8)
                monthControl(copy)
                headerIcon(searchOpen ? "xmark" : "magnifyingglass", label: copy.searchPlaceholder) {
                    searchOpen.toggle()
                    if !searchOpen { screen.search = "" }
                }
                headerIcon(screen.showCalendar ? "list.bullet" : "calendar", label: screen.showCalendar ? copy.txViewList : copy.txViewCalendar) {
                    screen.showCalendar.toggle()
                    if screen.showCalendar, screen.calendarDay == nil { screen.calendarDay = QCLedgerDay.today() }
                }
            }
            .pageTitleBar()
            if searchOpen {
                searchField(copy)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 8)
            }
            QCPageScroll(place: "activity", bottom: 128) {
                flowStrip(copy, spend: spend, income: income)
                QCSegmentControl(labels: [copy.filterAll, copy.filterOpen, copy.filterDone], index: statusIndex) { index in
                    screen.status = ["all", "open", "done"][index]
                }
                activeFilters(copy, accountName: accountName)
                VStack(alignment: .leading, spacing: 12) {
                    if !parts.isEmpty {
                        QCPanelCard(
                            title: "\(copy.category) · \(copy.periodChip(mode: screen.txMode, from: screen.txFrom, to: screen.txTo))",
                            titleSize: 15,
                            card: true
                        ) {
                            HStack(alignment: .top, spacing: 12) {
                                QCSpendDonut(parts: parts, total: total, mark: store.book.mark, caption: copy.periodSpend, active: screen.category) { name in
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
                        QCCalendarMonth(copy: copy, spend: spendByDay, anchor: monthAnchor, selected: screen.calendarDay ?? QCLedgerDay.today()) { day in
                            screen.calendarDay = day
                        }
                        .transition(.opacity)
                    }
                    QCPanelCard(title: listTitle) {
                        if listed.isEmpty {
                            emptyPeriod(copy)
                        } else {
                            rows(listed, copy: copy)
                        }
                    }
                }
            .animation(QCLedgerScreen.fold, value: screen.showCalendar)
            .onChange(of: searchOpen) { open in
                searchFocused = open
            }
        }
        }
    }

    private func headerIcon(_ name: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(QCPalette.ink)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func monthControl(_ copy: QCLedgerCopy) -> some View {
        HStack(spacing: 0) {
            Button { stepMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
                    .frame(width: 22, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                screen.open(.filter(which: "transactions"))
            } label: {
                Text(heading(copy))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .buttonStyle(.plain)
            Button { stepMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(canStepForward ? QCPalette.ink : QCPalette.faint)
                    .frame(width: 22, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canStepForward)
        }
    }

    private func searchField(_ copy: QCLedgerCopy) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(QCPalette.muted)
            TextField(copy.searchPlaceholder, text: $screen.search)
                .focused($searchFocused)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .font(.system(size: 15))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
    }

    private var monthAnchor: Date {
        QCLedgerDay.parse(QCLedgerDay.bounds(mode: screen.txMode, from: screen.txFrom, to: screen.txTo).start)
    }

    private var canStepForward: Bool {
        QCLedgerDay.bounds(mode: screen.txMode, from: screen.txFrom, to: screen.txTo).start < QCLedgerDay.monthStart()
    }

    private func heading(_ copy: QCLedgerCopy) -> String {
        if let month = wholeMonthNumber() { return copy.monthUnit(month) }
        return copy.periodChip(mode: screen.txMode, from: screen.txFrom, to: screen.txTo)
    }

    /// A range that covers one calendar month reads as that month. Today and custom spans keep their own label.
    private func wholeMonthNumber() -> Int? {
        if screen.txMode == .today { return nil }
        if screen.txMode == .month { return QCLedgerDay.month(of: Date()) }
        let start = min(screen.txFrom, screen.txTo)
        let end = max(screen.txFrom, screen.txTo)
        let bits = start.split(separator: "-")
        guard bits.count == 3, bits[2] == "01", let year = Int(bits[0]), let month = Int(bits[1]) else { return nil }
        let count = Calendar.current.range(of: .day, in: .month, for: QCLedgerDay.parse(start))?.count ?? 0
        if end == QCLedgerDay.iso(year: year, month: month, day: count) { return month }
        return nil
    }

    private func stepMonth(_ delta: Int) {
        if delta > 0, !canStepForward { return }
        let anchor = QCLedgerDay.bounds(mode: screen.txMode, from: screen.txFrom, to: screen.txTo).start
        guard let shifted = Calendar.current.date(byAdding: .month, value: delta, to: QCLedgerDay.parse(anchor)) else { return }
        let parts = Calendar.current.dateComponents([.year, .month], from: shifted)
        let year = parts.year ?? 2026
        let month = parts.month ?? 1
        let start = QCLedgerDay.iso(year: year, month: month, day: 1)
        if start > QCLedgerDay.monthStart() { return }
        if start == QCLedgerDay.monthStart() {
            screen.txMode = .month
            screen.txFrom = start
            screen.txTo = QCLedgerDay.today()
        } else {
            let count = Calendar.current.range(of: .day, in: .month, for: shifted)?.count ?? 28
            screen.txMode = .range
            screen.txFrom = start
            screen.txTo = QCLedgerDay.iso(year: year, month: month, day: count)
        }
        let today = QCLedgerDay.today()
        if screen.showCalendar {
            screen.calendarDay = today.hasPrefix(String(start.prefix(7))) ? today : start
        }
    }

    private func emptyPeriod(_ copy: QCLedgerCopy) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(QCPalette.down)
                .frame(width: 76, height: 76)
                .background(QCPalette.pink.opacity(0.45), in: Circle())
            Text(copy.txEmpty)
                .font(.system(size: 15))
                .foregroundStyle(QCPalette.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            QCPillButton(title: copy.entryNew) {
                screen.openNewRecord(store: store)
            }
            .frame(width: UIScreen.main.bounds.width / 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private func rows(_ listed: [QCEntry], copy: QCLedgerCopy) -> some View {
        let groups = dayGroups(listed)
        let flat = groups.flatMap(\.entries)
        let firstOfDay = Dictionary(uniqueKeysWithValues: groups.map { ($0.day, $0.entries.first?.id) })
        return LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(Array(flat.enumerated()), id: \.element.id) { index, entry in
                if !screen.showCalendar, firstOfDay[entry.date] == entry.id {
                    dayHead(entry.date, entries: groups.first { $0.day == entry.date }?.entries ?? [], copy: copy)
                        .padding(.top, index == 0 ? 0 : 10)
                }
                QCTxRow(
                    entry: entry,
                    mark: store.book.mark,
                    marks: store.book.categoryMarks,
                    copy: copy,
                    showTopBorder: index > 0,
                    onOpen: { screen.open(.entry(id: entry.id)) },
                    onToggle: { store.toggleChecked(entry.id) }
                )
            }
        }
    }

    private func rankRow(_ part: QCCategoryPart, total: Double, previous: Double, copy: QCLedgerCopy) -> some View {
        let active = screen.category == part.name
        return Button {
            screen.category = active ? nil : part.name
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    QCCategoryBadge(
                        style: QCCategoryMarks.style(name: part.name, marks: store.book.categoryMarks),
                        selected: active,
                        side: 22
                    )
                    Text(part.name)
                        .font(.system(size: 13, weight: active ? .heavy : .semibold))
                        .foregroundStyle(QCPalette.ink)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 2) {
                        QCMoneyText(value: part.amount, mark: store.book.mark, size: 13)
                        rankLabel(part.amount, previous: previous, copy: copy)
                    }
                }
                QCPortionBar(
                    fraction: total > 0 ? part.amount / total : 0,
                    tint: QCPalette.slice(part.colorIndex),
                    height: 4
                )
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func flowStrip(_ copy: QCLedgerCopy, spend: Double, income: Double) -> some View {
        let balance = income - spend
        return HStack(spacing: 0) {
            flowCell(copy.periodSpend, spend, active: screen.txDirection == "out", color: QCPalette.down) {
                screen.txDirection = screen.txDirection == "out" ? "all" : "out"
            }
            flowCell(copy.periodIncome, income, active: screen.txDirection == "in", color: QCPalette.up) {
                screen.txDirection = screen.txDirection == "in" ? "all" : "in"
            }
            flowCell(copy.periodBalance, balance, active: false, color: balance >= 0 ? QCPalette.up : QCPalette.down, signed: true) {
                screen.txDirection = "all"
            }
        }
        .padding(8)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
    }

    private func flowCell(_ title: String, _ value: Double, active: Bool, color: Color, signed: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(QCPalette.muted)
                QCMoneyText(value: value, mark: store.book.mark, size: 16, signed: signed, color: color)
                Capsule()
                    .fill(active ? color : Color.clear)
                    .frame(width: 16, height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func dayHead(_ day: String, entries: [QCEntry], copy: QCLedgerCopy) -> some View {
        let out = entries.filter { $0.isOut && !$0.isTransfer }.reduce(0) { $0 + $1.amount }
        let income = entries.filter { !$0.isOut && !$0.isTransfer }.reduce(0) { $0 + $1.amount }
        return Button {
            screen.calendarDay = day
            screen.showCalendar = true
        } label: {
            HStack(spacing: 8) {
                Text(copy.dayChip(day))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
                Spacer(minLength: 8)
                if out > 0 {
                    QCMoneyText(value: out, mark: store.book.mark, size: 12, color: QCPalette.down)
                }
                if income > 0 {
                    QCMoneyText(value: income, mark: store.book.mark, size: 12, color: QCPalette.up)
                }
            }
            .padding(.bottom, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func inSpan(keepingCategory: Bool = true) -> [QCEntry] {
        let bounds = QCLedgerDay.bounds(mode: screen.txMode, from: screen.txFrom, to: screen.txTo)
        let query = screen.search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let pool = screen.txUnscoped ? store.book.entries : QCBookMath.byScope(store.book.entries, screen.txScope)
        return QCBookMath.inPeriod(pool, bounds).filter { entry in
            if entry.id.hasPrefix("sample-") { return false }
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

    private func directed(_ entries: [QCEntry]) -> [QCEntry] {
        switch screen.txDirection {
        case "out": return entries.filter(\.isOut)
        case "in": return entries.filter { !$0.isOut }
        default: return entries
        }
    }

    private var statusIndex: Int {
        switch screen.status {
        case "open": return 1
        case "done": return 2
        default: return 0
        }
    }

    private func activeFilters(_ copy: QCLedgerCopy, accountName: String?) -> some View {
        var items: [(title: String, value: String)] = []
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
        return Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(rows.indices, id: \.self) { index in
                        HStack(spacing: 12) {
                            ForEach(rows[index], id: \.value) { item in
                                statusChip(item.title, item.value)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GeometryReader { proxy in
                    Color.clear.preference(key: QCFilterWidthKey.self, value: proxy.size.width)
                })
                .onPreferenceChange(QCFilterWidthKey.self) { next in
                    if abs(next - filterWidth) > 0.5 { filterWidth = next }
                }
            }
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
            let next = row.isEmpty ? chip : used + 12 + chip
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
        .foregroundStyle(selected ? QCPalette.ink : QCPalette.muted)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .background(selected ? QCPalette.pink : Color.white, in: Capsule())
        .overlay(Capsule().stroke(selected ? QCPalette.pink : QCPalette.line, lineWidth: 1))
    }

    private func rankLabel(_ amount: Double, previous: Double, copy: QCLedgerCopy) -> some View {
        let label: String
        let color: Color
        if amount > previous {
            label = copy.rankUp
            color = QCPalette.down
        } else if amount < previous {
            label = copy.rankDown
            color = QCPalette.up
        } else {
            label = copy.rankFlat
            color = QCPalette.muted
        }
        return Text(label).font(.system(size: 11, weight: .bold)).foregroundStyle(color)
    }

    private func dayGroups(_ entries: [QCEntry]) -> [(day: String, entries: [QCEntry])] {
        var grouped: [String: [QCEntry]] = [:]
        for entry in entries {
            grouped[entry.date, default: []].append(entry)
        }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0] ?? []) }
    }
}

private struct QCFilterWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
