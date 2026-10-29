//
//  DashboardStatsPanel.swift
//  transaction
//
//  Created by Lzl on 2026/10/29.
//

import SwiftUI
import UIKit

/// Totals, the comparison, the mix, and the top 10.
struct DashboardStatsPanel: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    var copy: LedgerCopy
    var entries: [Entry]

    @State private var annual = false
    @State private var kind = "out"
    @State private var cursor = LedgerDay.yearMonth(Date())
    @State private var toolsWidth: CGFloat = 0

    var body: some View {
        let current = LedgerDay.yearMonth(Date())
        let shown = cursor > current ? current : cursor
        let kindName = copy.statsKindName(kind)
        let window = windowEntries(shown)
        let total = window.reduce(0) { $0 + $1.amount }
        let bars = barKeys(shown, current: current)
        let peak = bars.map { monthTotal($0) }.max() ?? 0
        let when = periodName(shown, current: current)
        let mix = grouped(window, byCategory: true)
        let rank = Array(grouped(window, byCategory: false).prefix(10))
        let span = periodBounds(shown)

        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 22) {
                spanTab(copy.statsMonthly, on: !annual) { annual = false }
                spanTab(copy.statsAnnual, on: annual) { annual = true }
            }
            Group {
                if kindsOverflow(copy) {
                    VStack(alignment: .leading, spacing: 10) {
                        dateControl(shown: shown, current: current, copy: copy)
                        kindRow(copy)
                    }
                } else {
                    HStack(spacing: 8) {
                        dateControl(shown: shown, current: current, copy: copy)
                        kindRow(copy)
                    }
                }
            }
            .onPreferenceChange(ToolsWidthKey.self) { width in
                if abs(width - toolsWidth) > 0.5 { toolsWidth = width }
            }
            Button {
                screen.openStats(from: span.start, to: span.end, kind: kind, category: nil, title: nil)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(copy.statsCount(window.count, kind: kindName))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.muted)
                    MoneyText(value: total, mark: store.book.mark, size: 36)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Text(copy.statsCompare(annual: annual, kind: kindName))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Palette.ink)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(bars, id: \.self) { key in
                    bar(key, peak: peak, current: current, shown: shown)
                }
            }
            .frame(height: 168, alignment: .bottom)

            Text(copy.statsCompose(when, kind: kindName))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Palette.ink)
            if mix.isEmpty {
                Text(copy.statsEmpty).font(.system(size: 14)).foregroundStyle(Palette.muted)
            } else {
                let top = mix.map(\.amount).max() ?? 1
                ForEach(Array(mix.enumerated()), id: \.element.name) { _, item in
                    Button {
                        screen.openStats(from: span.start, to: span.end, kind: kind, category: item.name, title: nil)
                    } label: {
                        mixRow(item.name, amount: item.amount, share: item.amount / top)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(copy.statsRank(when, kind: kindName))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Palette.ink)
            if rank.isEmpty {
                Text(copy.statsEmpty).font(.system(size: 14)).foregroundStyle(Palette.muted)
            } else {
                ForEach(Array(rank.enumerated()), id: \.element.name) { index, item in
                    Button {
                        screen.openStats(from: span.start, to: span.end, kind: kind, category: nil, title: item.name)
                    } label: {
                        rankRow(index: index, name: item.name, amount: item.amount)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Palette.line, lineWidth: 1))
        .overlay(GeometryReader { geo in
            Color.clear.preference(key: ToolsWidthKey.self, value: max(0, geo.size.width - 32))
        })
    }

    private func dateControl(shown: String, current: String, copy: LedgerCopy) -> some View {
        HStack(spacing: 0) {
            stepButton(copy.statsPrev, system: "chevron.left", enabled: canStep(shown, by: -1, current: current)) {
                cursor = stepped(shown, by: -1, current: current)
            }
            Text(annual ? String(shown.prefix(4)) : shown.replacingOccurrences(of: "-", with: "/"))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Palette.ink)
                .frame(minWidth: annual ? 52 : 64)
            stepButton(copy.statsNext, system: "chevron.right", enabled: canStep(shown, by: 1, current: current)) {
                cursor = stepped(shown, by: 1, current: current)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color.white, in: Capsule())
        .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
        .fixedSize(horizontal: true, vertical: false)
    }

    private func kindRow(_ copy: LedgerCopy) -> some View {
        HStack(spacing: 8) {
            kindTab(copy.statsOut, id: "out")
            kindTab(copy.statsIn, id: "in")
            kindTab(copy.statsOther, id: "other")
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    /// Short labels stay with the month. Longer ones wrap whole, never clipped.
    private func kindsOverflow(_ copy: LedgerCopy) -> Bool {
        let width = toolsWidth > 0 ? toolsWidth : UIScreen.main.bounds.width - 52
        let font = UIFont.systemFont(ofSize: 13, weight: .bold)
        let pills = [copy.statsOut, copy.statsIn, copy.statsOther].reduce(CGFloat(0)) { total, label in
            total + ceil((label as NSString).size(withAttributes: [.font: font]).width) + 26
        }
        let date = CGFloat(28 + 28 + (annual ? 52 : 64) + 10)
        return date + 8 + pills + 16 > width
    }

    private func spanTab(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(on ? Palette.ink : Palette.faint)
                .padding(.bottom, 8)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(on ? Palette.pink : Color.clear).frame(height: 2)
                }
        }
        .buttonStyle(.plain)
    }

    private func kindTab(_ title: String, id: String) -> some View {
        let on = kind == id
        return Button { kind = id } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .background(on ? Palette.pink : Color.white, in: Capsule())
        .overlay(Capsule().stroke(on ? Palette.pink : Palette.line, lineWidth: 1))
    }

    private func stepButton(_ label: String, system: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(enabled ? Palette.ink : Palette.faint)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func bar(_ key: String, peak: Double, current: String, shown: String) -> some View {
        let amount = monthTotal(key)
        let future = key > current
        let selected = !annual && key == shown
        let height = peak > 0 ? max(4, CGFloat(amount / peak) * 108) : 4
        let month = Int(key.suffix(2)) ?? 0
        return Button {
            guard !future else { return }
            cursor = key
            annual = false
        } label: {
            VStack(spacing: 6) {
                if amount > 0 {
                    MoneyText(value: amount, mark: store.book.mark, size: 9, color: Palette.muted)
                } else {
                    Text(" ")
                        .font(.system(size: 9))
                }
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selected ? Palette.pink : Palette.wash)
                    .frame(height: height)
                    .frame(maxWidth: 36)
                Text("\(month)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(selected ? Palette.ink : Palette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
            .opacity(future ? 0.35 : 1)
        }
        .buttonStyle(.plain)
        .disabled(future)
    }

    private func mixRow(_ name: String, amount: Double, share: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Spacer(minLength: 8)
                MoneyText(value: amount, mark: store.book.mark, size: 14)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Palette.faint)
            }
            PortionBar(fraction: share, tint: Palette.pink, track: Palette.neutral, height: 8)
        }
        .padding(.vertical, 6)
    }

    private func rankRow(index: Int, name: String, amount: Double) -> some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.muted)
                .frame(width: 16)
            Text(String(name.prefix(1)))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Palette.ink)
                .frame(width: 32, height: 32)
                .background(Palette.slice(index).opacity(0.2), in: Circle())
            Text(name)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
            Spacer(minLength: 8)
            MoneyText(value: amount, mark: store.book.mark, size: 15)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Palette.faint)
        }
        .padding(.vertical, 6)
    }

    private func matches(_ entry: Entry) -> Bool {
        switch kind {
        case "in": return !entry.isOut && !entry.isTransfer
        case "other": return entry.isTransfer && entry.isOut
        default: return entry.isOut && !entry.isTransfer
        }
    }

    private func windowEntries(_ shown: String) -> [Entry] {
        let today = LedgerDay.today()
        return entries.filter { entry in
            guard matches(entry), entry.date <= today else { return false }
            if annual { return entry.date.hasPrefix(String(shown.prefix(4))) }
            return entry.date.hasPrefix(shown)
        }
    }

    private func monthTotal(_ key: String) -> Double {
        let today = LedgerDay.today()
        return entries.reduce(0) { sum, entry in
            guard matches(entry), entry.date.hasPrefix(key), entry.date <= today else { return sum }
            return sum + entry.amount
        }
    }

    private func grouped(_ list: [Entry], byCategory: Bool) -> [(name: String, amount: Double)] {
        var totals: [String: Double] = [:]
        for entry in list {
            let name = (byCategory ? entry.category : entry.title).trimmingCharacters(in: .whitespacesAndNewlines)
            let key = name.isEmpty ? "—" : name
            totals[key, default: 0] += entry.amount
        }
        return totals.map { (name: $0.key, amount: $0.value) }.sorted { $0.amount > $1.amount }
    }

    private func barKeys(_ shown: String, current: String) -> [String] {
        if annual {
            let year = Int(shown.prefix(4)) ?? 0
            return (1...12).map { String(format: "%04d-%02d", year, $0) }
        }
        return (0..<6).map { shift(shown, by: $0 - 5) }.filter { $0 <= current || $0 == shown }
    }

    private func periodName(_ shown: String, current: String) -> String {
        if annual {
            let year = String(shown.prefix(4))
            return year == String(current.prefix(4)) ? copy.statsThisYear : year
        }
        return shown == current ? copy.statsThisMonth : shown.replacingOccurrences(of: "-", with: "/")
    }

    private func periodBounds(_ shown: String) -> (start: String, end: String) {
        if annual {
            let year = String(shown.prefix(4))
            return ("\(year)-01-01", "\(year)-12-31")
        }
        let parts = shown.split(separator: "-")
        let year = Int(parts.first ?? "") ?? 0
        let month = Int(parts.last ?? "") ?? 1
        let start = LedgerDay.iso(year: year, month: month, day: 1)
        let next = shift(shown, by: 1)
        let nextParts = next.split(separator: "-")
        let nextStart = LedgerDay.iso(year: Int(nextParts.first ?? "") ?? year, month: Int(nextParts.last ?? "") ?? month, day: 1)
        return (start, LedgerDay.adding(days: -1, to: nextStart))
    }

    private func canStep(_ shown: String, by delta: Int, current: String) -> Bool {
        let next = stepped(shown, by: delta, current: current)
        if delta > 0 { return next > shown && next <= current }
        let floor = shift(current, by: annual ? -60 : -36)
        return next < shown && next >= String(floor.prefix(annual ? 4 : 7))
    }

    private func stepped(_ shown: String, by delta: Int, current: String) -> String {
        let next = shift(shown, by: annual ? delta * 12 : delta)
        return next > current ? current : next
    }

    private func shift(_ key: String, by delta: Int) -> String {
        let parts = key.split(separator: "-")
        var comps = DateComponents()
        comps.year = Int(parts.first ?? "")
        comps.month = Int(parts.last ?? "")
        comps.day = 1
        let base = Calendar.current.date(from: comps) ?? Date()
        let next = Calendar.current.date(byAdding: .month, value: delta, to: base) ?? base
        return LedgerDay.yearMonth(next)
    }
}

private struct ToolsWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
