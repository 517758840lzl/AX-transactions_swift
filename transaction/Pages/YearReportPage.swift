//
//  YearReportPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/28.
//

import Combine
import SwiftUI

private struct YearBucket: Identifiable {
    var id: String
    var name: String
    var amount: Double
    var count: Int
}

/// Annual classification, month comparison, large entries, and per-account totals.
struct YearReportPage: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
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
        let columns = BookMath.yearColumns(BookMath.byScope(store.book.entries, screen.dashScope), year: year)
        let live = columns.filter { !upcoming($0.month) }
        let peak = live.map { columnAmount($0) }.max() ?? 0
        let average = live.isEmpty ? 0 : live.reduce(0) { $0 + columnAmount($1) } / Double(live.count)
        let peakMonth = live.max { lhs, rhs in
            let left = columnAmount(lhs)
            let right = columnAmount(rhs)
            if left == right { return lhs.month < rhs.month }
            return left < right
        }?.month
        let slices = buckets(picked, id: { $0.category }, name: { $0.category })
        let tops = picked.sorted { $0.amount > $1.amount }
        let shownTops = showAllTops ? Array(tops.prefix(30)) : Array(tops.prefix(5))
        let accounts = buckets(
            picked,
            id: { $0.accountId.isEmpty ? $0.accountName : $0.accountId },
            name: { entry in
                store.book.accounts.first { $0.id == entry.accountId }?.name ?? entry.accountName
            }
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SubpageHead(title: "\(year) \(copy.yearReport)", back: copy.back) { pageBack() }
                HStack {
                    Button(copy.yearPrev) { shiftYear(-1) }
                    Spacer()
                    Button(copy.yearNext) { shiftYear(1) }
                        .disabled(year >= Calendar.current.component(.year, from: Date()))
                        .opacity(year >= Calendar.current.component(.year, from: Date()) ? 0.35 : 1)
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Palette.ink)
                HStack(spacing: 8) {
                    kindPill(copy.statsOut, id: "out")
                    kindPill(copy.statsIn, id: "in")
                }
                hero(copy: copy, kindName: kindName, total: total, count: picked.count, balance: income - spend)
                classifyCard(copy: copy, slices: slices, total: total)
                compareCard(copy: copy, columns: columns, kindName: kindName, peak: peak, average: average, peakMonth: peak > 0 ? peakMonth : nil)
                if !shownTops.isEmpty {
                    topCard(copy: copy, kindName: kindName, rows: shownTops, expanded: showAllTops, more: tops.count > 5)
                }
                if !accounts.isEmpty {
                    accountCard(copy: copy, rows: accounts)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 32)
            .immediateScroll()
        }
        .background(Palette.stage)
    }

    private func hero(copy: LedgerCopy, kindName: String, total: Double, count: Int, balance: Double) -> some View {
        Button {
            openFeed(month: nil, category: nil, title: nil, account: nil)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(kindName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Palette.muted)
                MoneyText(value: total, mark: store.book.mark, size: 36)
                Text(copy.yearCount(count))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Palette.muted)
                HStack(spacing: 6) {
                    Text(copy.yearBalance)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Palette.muted)
                    MoneyText(value: balance, mark: store.book.mark, size: 14, signed: true, color: Palette.ink)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Palette.wash, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                Text(String(year))
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(Palette.pink.opacity(0.55))
                    .padding(.trailing, 12)
                    .padding(.bottom, 4)
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
    }

    private func classifyCard(copy: LedgerCopy, slices: [YearBucket], total: Double) -> some View {
        card(copy.yearClassify) {
            if slices.isEmpty {
                Text(copy.statsEmpty)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Palette.muted)
            } else {
                ring(slices, total: total)
                ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Button {
                                openCategory = openCategory == slice.id ? "" : slice.id
                            } label: {
                                HStack(spacing: 8) {
                                    Circle().fill(Palette.slice(index)).frame(width: 8, height: 8)
                                    Text("\(index + 1). \(slice.name)  \(percent(slice.amount, total))")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Palette.ink)
                                        .lineLimit(1)
                                    Spacer(minLength: 4)
                                    Image(systemName: openCategory == slice.id ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Palette.faint)
                                }
                            }
                            .buttonStyle(.plain)
                            Button {
                                openFeed(month: nil, category: slice.name, title: nil, account: nil)
                            } label: {
                                HStack(spacing: 4) {
                                    MoneyText(value: slice.amount, mark: store.book.mark, size: 14)
                                    Text(copy.yearCount(slice.count))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Palette.muted)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Palette.faint)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        if openCategory == slice.id {
                            titleGrid(slice.name)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func ring(_ slices: [YearBucket], total: Double) -> some View {
        let rings = ringSlices(slices, total: total)
        return GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            ZStack {
                ForEach(Array(rings.enumerated()), id: \.element.id) { index, ring in
                    Circle()
                        .trim(from: CGFloat(ring.start), to: CGFloat(ring.end))
                        .stroke(Palette.slice(index), style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                        .frame(width: 132, height: 132)
                }
            }
            .rotationEffect(.degrees(-90))
            .position(x: cx, y: cy)
            ForEach(rings.filter { $0.share >= 0.08 }) { ring in
                Text(percent(ring.amount, total))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Palette.ink)
                    .position(x: cx + CGFloat(cos(ring.radians)) * 102, y: cy + CGFloat(sin(ring.radians)) * 86)
            }
        }
        .frame(height: 188)
    }

    private func titleGrid(_ category: String) -> some View {
        let titles = buckets(yearEntries().filter { matches($0) && $0.category == category }, id: { $0.title }, name: { $0.title })
        return VStack(spacing: 8) {
            ForEach(Array(stride(from: 0, to: titles.count, by: 3)), id: \.self) { start in
                let row = Array(titles[start..<min(start + 3, titles.count)])
                HStack(spacing: 8) {
                    ForEach(row) { item in
                        Button {
                            openFeed(month: nil, category: category, title: item.name, account: nil)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(String(item.name.prefix(1)))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Palette.ink)
                                    .frame(width: 28, height: 28)
                                    .background(Palette.wash, in: Circle())
                                Text(item.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Palette.ink)
                                    .lineLimit(1)
                                MoneyText(value: item.amount, mark: store.book.mark, size: 13)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
                            .background(Palette.neutral, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    if row.count < 3 {
                        ForEach(0..<(3 - row.count), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private func compareCard(copy: LedgerCopy, columns: [YearColumn], kindName: String, peak: Double, average: Double, peakMonth: Int?) -> some View {
        card(copy.yearCompare) {
            Color.clear
                .frame(height: 46)
                .overlay {
                    GeometryReader { geo in
                        if let peakMonth, peak > 0 {
                            let slot = geo.size.width / 12
                            let center = slot * (CGFloat(peakMonth) - 0.5)
                            let bubbleX = min(max(center, 58), geo.size.width - 58)
                            VStack(spacing: 2) {
                                Text(copy.yearMost("\(year)/\(peakMonth)"))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Palette.ink)
                                MoneyText(value: columnAmount(columns[peakMonth - 1]), mark: store.book.mark, size: 12)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Palette.pink, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .position(x: bubbleX, y: 16)
                            Rectangle()
                                .fill(Palette.pink)
                                .frame(width: 1, height: 10)
                                .position(x: center, y: 40)
                        }
                    }
                }
            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(columns) { column in
                        let value = columnAmount(column)
                        let height = peak > 0 ? max(value > 0 ? 8 : 4, 120 * value / peak) : 4
                        Button {
                            openFeed(month: column.month, category: nil, title: nil, account: nil)
                        } label: {
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(column.month == peakMonth && value > 0 ? Palette.pink : Palette.wash)
                                    .frame(height: height)
                                    .padding(.horizontal, 2)
                                Text("\(column.month)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(column.month == peakMonth ? Palette.ink : Palette.muted)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(upcoming(column.month))
                        .opacity(upcoming(column.month) ? 0.35 : 1)
                        .frame(maxWidth: .infinity)
                    }
                }
                if peak > 0 {
                    Canvas { context, size in
                        var path = Path()
                        let y = size.height - 18 - (120 * average / peak)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        context.stroke(path, with: .color(Palette.faint), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(height: 148)
            HStack(spacing: 6) {
                Spacer()
                Rectangle().fill(Palette.faint).frame(width: 14, height: 1)
                Text(copy.yearAverage(kindName))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Palette.muted)
                MoneyText(value: average, mark: store.book.mark, size: 12, color: Palette.muted)
                Spacer()
            }
        }
    }

    private func topCard(copy: LedgerCopy, kindName: String, rows: [Entry], expanded: Bool, more: Bool) -> some View {
        card(copy.yearTop(kindName)) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, entry in
                let paidBack = refunded(entry.id)
                Button {
                    screen.open(.entry(id: entry.id))
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Palette.faint)
                            .frame(width: 16, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Palette.ink)
                                .lineLimit(1)
                            Text(entry.category)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Palette.muted)
                            if paidBack > 0 {
                                HStack(spacing: 4) {
                                    Text(copy.yearRefunded)
                                    MoneyText(value: paidBack, mark: store.book.mark, size: 12, color: Palette.down)
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Palette.down)
                            }
                        }
                        Spacer(minLength: 8)
                        VStack(alignment: .trailing, spacing: 2) {
                            MoneyText(value: entry.amount, mark: store.book.mark, size: 15)
                            Text(shortDate(entry.date))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Palette.faint)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
            if more {
                Button(expanded ? copy.yearFold : copy.yearExpand) {
                    showAllTops.toggle()
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Palette.ink)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func accountCard(copy: LedgerCopy, rows: [YearBucket]) -> some View {
        card(copy.yearAccount(out: kind != "in")) {
            ForEach(rows) { row in
                Button {
                    openFeed(month: nil, category: nil, title: nil, account: row.id)
                } label: {
                    HStack(spacing: 10) {
                        Text(String(row.name.prefix(1)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Palette.ink)
                            .frame(width: 32, height: 32)
                            .background(Palette.wash, in: Circle())
                        Text(row.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Palette.ink)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        VStack(alignment: .trailing, spacing: 2) {
                            MoneyText(value: row.amount, mark: store.book.mark, size: 15)
                            Text(copy.yearCount(row.count))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Palette.muted)
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Palette.faint)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Palette.ink)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func kindPill(_ title: String, id: String) -> some View {
        let on = kind == id
        return Button(title) {
            kind = id
            openCategory = ""
            showAllTops = false
        }
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(on ? Palette.ink : Palette.muted)
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .background(on ? Palette.pink : Color.white, in: Capsule())
        .overlay(Capsule().stroke(on ? Color.clear : Palette.line, lineWidth: 1))
    }

    private func yearEntries() -> [Entry] {
        let prefix = String(format: "%04d", year)
        return BookMath.byScope(store.book.entries, screen.dashScope).filter { $0.date.hasPrefix(prefix) }
    }

    private func matches(_ entry: Entry) -> Bool {
        if kind == "in" { return !entry.isOut && !entry.isTransfer }
        return entry.isOut && !entry.isTransfer
    }

    private func columnAmount(_ column: YearColumn) -> Double {
        kind == "in" ? column.income : column.spend
    }

    private func summed(_ entries: [Entry]) -> Double {
        LedgerMoney.cents(entries.reduce(0) { $0 + $1.amount })
    }

    private func buckets(_ entries: [Entry], id: (Entry) -> String, name: (Entry) -> String) -> [YearBucket] {
        var map: [String: YearBucket] = [:]
        for entry in entries {
            let key = id(entry)
            var bucket = map[key] ?? YearBucket(id: key, name: name(entry), amount: 0, count: 0)
            bucket.amount = LedgerMoney.cents(bucket.amount + entry.amount)
            bucket.count += 1
            map[key] = bucket
        }
        return map.values.sorted { $0.amount > $1.amount }
    }

    private func refunded(_ id: String) -> Double {
        LedgerMoney.cents(store.book.entries.filter { $0.refundOf == id }.reduce(0) { $0 + $1.amount })
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

    private func percent(_ amount: Double, _ total: Double) -> String {
        guard total > 0 else { return "0%" }
        let digits = String(format: "%.1f", amount / total * 100)
        let trimmed = digits.hasSuffix(".0") ? String(digits.dropLast(2)) : digits
        return trimmed + "%"
    }

    private func shortDate(_ iso: String) -> String {
        let parts = iso.split(separator: "-")
        guard parts.count == 3 else { return iso }
        return "\(parts[1])-\(parts[2])"
    }

    private func ringSlices(_ slices: [YearBucket], total: Double) -> [RingSlice] {
        var cursor = 0.0
        return slices.map { slice in
            let share = total > 0 ? slice.amount / total : 0
            let start = cursor
            cursor += share
            let mid = -90 + ((start + min(cursor, 0.999)) / 2) * 360
            return RingSlice(id: slice.id, amount: slice.amount, start: start, end: min(cursor, 0.999), share: share, radians: mid * .pi / 180)
        }
    }

    private func openFeed(month: Int?, category: String?, title: String?, account: String?) {
        let start: String
        let end: String
        if let month {
            let span = BookMath.monthSpan(year: year, month: month)
            start = span.start
            end = span.end
        } else {
            start = LedgerDay.iso(year: year, month: 1, day: 1)
            end = LedgerDay.iso(year: year, month: 12, day: 31)
        }
        screen.openStats(from: start, to: end, kind: kind, category: category, title: title)
        if let account {
            screen.accountId = account
        }
    }
}

private struct RingSlice: Identifiable {
    var id: String
    var amount: Double
    var start: Double
    var end: Double
    var share: Double
    var radians: Double
}
