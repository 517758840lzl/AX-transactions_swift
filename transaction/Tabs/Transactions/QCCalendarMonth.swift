//
//  QCCalendarMonth.swift
//  transaction
//
//  Created by Lzl on 2026/10/14.
//

import Combine
import SwiftUI

struct QCCalendarMonth: View {
    var copy: QCLedgerCopy
    var spend: [String: Double]
    var anchor: Date = Date()
    var selected: String
    var onSelect: (String) -> Void

    var body: some View {
        let model = QCMonthGrid.current(anchor: anchor)
        QCPanelCard(title: copy.monthUnit(model.month)) {
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    ForEach(copy.calendarWeek.indices, id: \.self) { index in
                        Text(copy.calendarWeek[index])
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(QCPalette.muted)
                            .frame(maxWidth: .infinity)
                    }
                }
                ForEach(model.rows.indices, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(model.rows[row]) { cell in
                            dayButton(cell)
                        }
                    }
                }
            }
        }
    }

    private func dayButton(_ cell: QCMonthDay) -> some View {
        let iso = cell.iso
        let marked = iso.map { (spend[$0] ?? 0) > 0 } ?? false
        return Button {
            if let iso { onSelect(iso) }
        } label: {
            VStack(spacing: 2) {
                Text(cell.day.map(String.init) ?? " ")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(QCPalette.ink)
                Circle()
                    .fill(marked ? (iso == selected ? QCPalette.down : QCPalette.pink) : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(iso == selected ? QCPalette.pink : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(cell.day == nil)
        .accessibilityHidden(cell.day == nil)
    }
}

private struct QCMonthDay: Identifiable {
    var id: Int
    var iso: String?
    var day: Int?
}

private enum QCMonthGrid {
    static func current(anchor: Date = Date()) -> (month: Int, rows: [[QCMonthDay]]) {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.year, .month], from: anchor)
        let year = parts.year ?? 2026
        let month = parts.month ?? 1
        let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? anchor
        let lead = calendar.component(.weekday, from: first) - 1
        let count = calendar.range(of: .day, in: .month, for: first)?.count ?? 30
        var cells: [QCMonthDay] = (0..<lead).map { QCMonthDay(id: -$0 - 1, iso: nil, day: nil) }
        for day in 1...count {
            cells.append(QCMonthDay(id: day, iso: QCLedgerDay.iso(year: year, month: month, day: day), day: day))
        }
        while cells.count % 7 != 0 {
            cells.append(QCMonthDay(id: -(cells.count + 1), iso: nil, day: nil))
        }
        let rows = stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
        return (month, rows)
    }
}
