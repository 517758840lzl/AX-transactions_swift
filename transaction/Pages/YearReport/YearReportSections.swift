//
//  YearReportSections.swift
//  transaction
//
//  Created by Lzl on 2026/10/28.
//

import SwiftUI

struct YearBucket: Identifiable {
    var id: String
    var name: String
    var amount: Double
    var count: Int
}

enum YearReportGroup {
    static func buckets(_ entries: [Entry], id: (Entry) -> String, name: (Entry) -> String) -> [YearBucket] {
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
}

struct YearReportCard<Content: View>: View {
    var title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
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
}

struct YearReportClassify: View {
    var copy: LedgerCopy
    var mark: String
    var marks: [String: String]
    var slices: [YearBucket]
    var total: Double
    @Binding var openCategory: String
    var titles: (String) -> [YearBucket]
    var openSlice: (YearBucket) -> Void
    var openTitle: (String, String) -> Void
    var onAdd: () -> Void

    var body: some View {
        YearReportCard(title: copy.yearClassify) {
            if slices.isEmpty {
                HStack(spacing: 0) {
                    Text(copy.statsEmpty)
                        .foregroundColor(Palette.muted)
                    Button(action: onAdd) {
                        Text(copy.statsEmptyAdd)
                            .foregroundColor(Palette.ink)
                    }
                    .buttonStyle(.plain)
                }
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
            } else {
                ring(slices, total: total)
                ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Button {
                                openCategory = openCategory == slice.id ? "" : slice.id
                            } label: {
                                HStack(spacing: 8) {
                                    CategoryBadge(
                                        style: CategoryMarks.style(name: slice.name, marks: marks),
                                        selected: false,
                                        side: 28
                                    )
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
                                openSlice(slice)
                            } label: {
                                HStack(spacing: 4) {
                                    MoneyText(value: slice.amount, mark: mark, size: 14)
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

    private func titleGrid(_ category: String) -> some View {
        let rows = titles(category)
        return VStack(spacing: 8) {
            ForEach(Array(stride(from: 0, to: rows.count, by: 3)), id: \.self) { start in
                let row = Array(rows[start..<min(start + 3, rows.count)])
                HStack(spacing: 8) {
                    ForEach(row) { item in
                        Button {
                            openTitle(category, item.name)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                CategoryBadge(
                                    style: CategoryMarks.style(name: category, marks: marks),
                                    selected: false,
                                    side: 28
                                )
                                Text(item.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Palette.ink)
                                    .lineLimit(1)
                                MoneyText(value: item.amount, mark: mark, size: 13)
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

    private func percent(_ amount: Double, _ total: Double) -> String {
        guard total > 0 else { return "0%" }
        let digits = String(format: "%.1f", amount / total * 100)
        let trimmed = digits.hasSuffix(".0") ? String(digits.dropLast(2)) : digits
        return trimmed + "%"
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
}

struct YearReportCompare: View {
    var copy: LedgerCopy
    var mark: String
    var year: Int
    var kindName: String
    var columns: [YearColumn]
    var peak: Double
    var average: Double
    var peakMonth: Int?
    var amount: (YearColumn) -> Double
    var upcoming: (Int) -> Bool
    var openMonth: (Int) -> Void

    var body: some View {
        YearReportCard(title: copy.yearCompare) {
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
                                MoneyText(value: amount(columns[peakMonth - 1]), mark: mark, size: 12)
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
                        let value = amount(column)
                        let height = peak > 0 ? max(value > 0 ? 8 : 4, 120 * value / peak) : 4
                        Button {
                            openMonth(column.month)
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
                MoneyText(value: average, mark: mark, size: 12, color: Palette.muted)
                Spacer()
            }
        }
    }
}

struct YearReportTops: View {
    var copy: LedgerCopy
    var mark: String
    var kindName: String
    var rows: [Entry]
    var expanded: Bool
    var more: Bool
    var refunded: (String) -> Double
    var toggle: () -> Void
    var openEntry: (String) -> Void

    var body: some View {
        YearReportCard(title: copy.yearTop(kindName)) {
            let scale = rows.first?.amount ?? 1
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, entry in
                let paidBack = refunded(entry.id)
                Button {
                    openEntry(entry.id)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(index + 1)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Palette.faint)
                                .frame(width: 16, alignment: .leading)
                            Text(entry.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Palette.ink)
                                .lineLimit(1)
                            MoneyText(value: entry.amount, mark: mark, size: 15)
                            Spacer(minLength: 0)
                        }
                        Text("\(entry.category) · \(shortDate(entry.date))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Palette.muted)
                            .padding(.leading, 24)
                        if paidBack > 0 {
                            HStack(spacing: 4) {
                                Text(copy.yearRefunded)
                                MoneyText(value: paidBack, mark: mark, size: 12, color: Palette.down)
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Palette.down)
                            .padding(.leading, 24)
                        }
                        PortionBar(fraction: scale > 0 ? entry.amount / scale : 0, tint: Palette.pink, height: 6)
                            .padding(.leading, 24)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
            if more {
                Button(expanded ? copy.yearFold : copy.yearExpand) {
                    toggle()
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Palette.ink)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func shortDate(_ iso: String) -> String {
        let parts = iso.split(separator: "-")
        guard parts.count == 3 else { return iso }
        return "\(parts[1])-\(parts[2])"
    }
}

struct YearReportAccounts: View {
    var copy: LedgerCopy
    var mark: String
    var outgoing: Bool
    var rows: [YearBucket]
    var openAccount: (String) -> Void

    var body: some View {
        YearReportCard(title: copy.yearAccount(out: outgoing)) {
            ForEach(rows) { row in
                Button {
                    openAccount(row.id)
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
                            MoneyText(value: row.amount, mark: mark, size: 15)
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
}

private struct RingSlice: Identifiable {
    var id: String
    var amount: Double
    var start: Double
    var end: Double
    var share: Double
    var radians: Double
}
