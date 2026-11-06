//
//  QCYearReportSections.swift
//  transaction
//
//  Created by Lzl on 2026/10/28.
//

import SwiftUI

struct QCYearBucket: Identifiable {
    var id: String
    var name: String
    var amount: Double
    var count: Int
}

enum QCYearReportGroup {
    static func buckets(_ entries: [QCEntry], id: (QCEntry) -> String, name: (QCEntry) -> String) -> [QCYearBucket] {
        var map: [String: QCYearBucket] = [:]
        for entry in entries {
            let key = id(entry)
            var bucket = map[key] ?? QCYearBucket(id: key, name: name(entry), amount: 0, count: 0)
            bucket.amount = QCLedgerMoney.cents(bucket.amount + entry.amount)
            bucket.count += 1
            map[key] = bucket
        }
        return map.values.sorted { $0.amount > $1.amount }
    }
}

struct QCYearReportCard<Content: View>: View {
    var title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(QCPalette.ink)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct QCYearReportClassify: View {
    var copy: QCLedgerCopy
    var mark: String
    var marks: [String: String]
    var slices: [QCYearBucket]
    var total: Double
    @Binding var openCategory: String
    var titles: (String) -> [QCYearBucket]
    var openSlice: (QCYearBucket) -> Void
    var openTitle: (String, String) -> Void
    var onAdd: () -> Void

    var body: some View {
        QCYearReportCard(title: copy.yearClassify) {
            if slices.isEmpty {
                HStack(spacing: 0) {
                    Text(copy.statsEmpty)
                        .foregroundColor(QCPalette.muted)
                    Button(action: onAdd) {
                        Text(copy.statsEmptyAdd)
                            .foregroundColor(QCPalette.ink)
                    }
                    .buttonStyle(.plain)
                }
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
            } else {
                ring(slices, total: total)
                ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 10) {
                            Button {
                                openCategory = openCategory == slice.id ? "" : slice.id
                            } label: {
                                HStack(alignment: .center, spacing: 10) {
                                    QCCategoryBadge(
                                        style: QCCategoryMarks.style(name: slice.name, marks: marks),
                                        selected: false,
                                        side: 28
                                    )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(index + 1). \(slice.name)")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(QCPalette.ink)
                                            .lineLimit(1)
                                        Text("\(percent(slice.amount, total)) · \(copy.yearCount(slice.count))")
                                            .font(.system(size: 12))
                                            .foregroundColor(QCPalette.muted)
                                            .lineLimit(1)
                                    }
                                    Spacer(minLength: 8)
                                    Image(systemName: openCategory == slice.id ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(QCPalette.faint)
                                }
                            }
                            .buttonStyle(.plain)
                            Button {
                                openSlice(slice)
                            } label: {
                                HStack(spacing: 2) {
                                    QCMoneyText(value: slice.amount, mark: mark, size: 14)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(QCPalette.faint)
                                }
                                .fixedSize()
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
                                QCCategoryBadge(
                                    style: QCCategoryMarks.style(name: category, marks: marks),
                                    selected: false,
                                    side: 28
                                )
                                Text(item.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(QCPalette.ink)
                                    .lineLimit(1)
                                QCMoneyText(value: item.amount, mark: mark, size: 13)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
                            .background(QCPalette.neutral, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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

    private func ring(_ slices: [QCYearBucket], total: Double) -> some View {
        let rings = ringSlices(slices, total: total)
        return GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            ZStack {
                ForEach(Array(rings.enumerated()), id: \.element.id) { index, ring in
                    Circle()
                        .trim(from: CGFloat(ring.start), to: CGFloat(ring.end))
                        .stroke(QCPalette.slice(index), style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                        .frame(width: 132, height: 132)
                }
            }
            .rotationEffect(.degrees(-90))
            .position(x: cx, y: cy)
            ForEach(rings.filter { $0.share >= 0.08 }) { ring in
                Text(percent(ring.amount, total))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(QCPalette.ink)
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

    private func ringSlices(_ slices: [QCYearBucket], total: Double) -> [QCRingSlice] {
        var cursor = 0.0
        return slices.map { slice in
            let share = total > 0 ? slice.amount / total : 0
            let start = cursor
            cursor += share
            let mid = -90 + ((start + min(cursor, 0.999)) / 2) * 360
            return QCRingSlice(id: slice.id, amount: slice.amount, start: start, end: min(cursor, 0.999), share: share, radians: mid * .pi / 180)
        }
    }
}

struct QCYearReportCompare: View {
    var copy: QCLedgerCopy
    var mark: String
    var year: Int
    var kindName: String
    var columns: [QCYearColumn]
    var peak: Double
    var average: Double
    var peakMonth: Int?
    var amount: (QCYearColumn) -> Double
    var upcoming: (Int) -> Bool
    var openMonth: (Int) -> Void

    var body: some View {
        QCYearReportCard(title: copy.yearCompare) {
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
                                    .foregroundColor(QCPalette.ink)
                                QCMoneyText(value: amount(columns[peakMonth - 1]), mark: mark, size: 12)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(QCPalette.pink, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .position(x: bubbleX, y: 16)
                            Rectangle()
                                .fill(QCPalette.pink)
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
                                    .fill(column.month == peakMonth && value > 0 ? QCPalette.pink : QCPalette.wash)
                                    .frame(height: height)
                                    .padding(.horizontal, 2)
                                Text("\(column.month)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(column.month == peakMonth ? QCPalette.ink : QCPalette.muted)
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
                        context.stroke(path, with: .color(QCPalette.faint), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(height: 148)
            HStack(spacing: 6) {
                Spacer()
                Rectangle().fill(QCPalette.faint).frame(width: 14, height: 1)
                Text(copy.yearAverage(kindName))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(QCPalette.muted)
                QCMoneyText(value: average, mark: mark, size: 12, color: QCPalette.muted)
                Spacer()
            }
        }
    }
}

struct QCYearReportTops: View {
    var copy: QCLedgerCopy
    var mark: String
    var kindName: String
    var rows: [QCEntry]
    var expanded: Bool
    var more: Bool
    var refunded: (String) -> Double
    var toggle: () -> Void
    var openEntry: (String) -> Void

    var body: some View {
        QCYearReportCard(title: copy.yearTop(kindName)) {
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
                                .foregroundColor(QCPalette.faint)
                                .frame(width: 16, alignment: .leading)
                            Text(entry.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(QCPalette.ink)
                                .lineLimit(1)
                            QCMoneyText(value: entry.amount, mark: mark, size: 15)
                            Spacer(minLength: 0)
                        }
                        Text("\(entry.category) · \(shortDate(entry.date))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(QCPalette.muted)
                            .padding(.leading, 24)
                        if paidBack > 0 {
                            HStack(spacing: 4) {
                                Text(copy.yearRefunded)
                                QCMoneyText(value: paidBack, mark: mark, size: 12, color: QCPalette.down)
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(QCPalette.down)
                            .padding(.leading, 24)
                        }
                        QCPortionBar(fraction: scale > 0 ? entry.amount / scale : 0, tint: QCPalette.pink, height: 6)
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
                .foregroundColor(QCPalette.ink)
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

struct QCYearReportAccounts: View {
    var copy: QCLedgerCopy
    var mark: String
    var outgoing: Bool
    var rows: [QCYearBucket]
    var openAccount: (String) -> Void

    var body: some View {
        QCYearReportCard(title: copy.yearAccount(out: outgoing)) {
            ForEach(rows) { row in
                Button {
                    openAccount(row.id)
                } label: {
                    HStack(spacing: 10) {
                        Text(String(row.name.prefix(1)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(QCPalette.ink)
                            .frame(width: 32, height: 32)
                            .background(QCPalette.wash, in: Circle())
                        Text(row.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(QCPalette.ink)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        VStack(alignment: .trailing, spacing: 2) {
                            QCMoneyText(value: row.amount, mark: mark, size: 15)
                            Text(copy.yearCount(row.count))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(QCPalette.muted)
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(QCPalette.faint)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct QCRingSlice: Identifiable {
    var id: String
    var amount: Double
    var start: Double
    var end: Double
    var share: Double
    var radians: Double
}
