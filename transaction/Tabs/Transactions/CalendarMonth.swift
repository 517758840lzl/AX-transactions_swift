//
//  CalendarMonth.swift
//  transaction
//
//  Created by Lzl on 2026/10/14.
//

import Combine
import SwiftUI

struct CalendarMonth: View {
    var copy: LedgerCopy
    var spend: [String: Double]
    var anchor: Date = Date()
    var selected: String
    var onSelect: (String) -> Void

    var body: some View {
        let model = MonthGrid.current(anchor: anchor)
        PanelCard(title: copy.monthUnit(model.month)) {
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    ForEach(copy.calendarWeek.indices, id: \.self) { index in
                        Text(copy.calendarWeek[index])
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Palette.muted)
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

    private func dayButton(_ cell: MonthDay) -> some View {
        let iso = cell.iso
        let marked = iso.map { (spend[$0] ?? 0) > 0 } ?? false
        return Button {
            if let iso { onSelect(iso) }
        } label: {
            VStack(spacing: 2) {
                Text(cell.day.map(String.init) ?? " ")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Circle()
                    .fill(marked ? (iso == selected ? Palette.down : Palette.pink) : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(iso == selected ? Palette.pink : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(cell.day == nil)
        .accessibilityHidden(cell.day == nil)
    }
}

private struct MonthDay: Identifiable {
    var id: Int
    var iso: String?
    var day: Int?
}

private enum MonthGrid {
    static func current(anchor: Date = Date()) -> (month: Int, rows: [[MonthDay]]) {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.year, .month], from: anchor)
        let year = parts.year ?? 2026
        let month = parts.month ?? 1
        let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? anchor
        let lead = calendar.component(.weekday, from: first) - 1
        let count = calendar.range(of: .day, in: .month, for: first)?.count ?? 30
        var cells: [MonthDay] = (0..<lead).map { MonthDay(id: -$0 - 1, iso: nil, day: nil) }
        for day in 1...count {
            cells.append(MonthDay(id: day, iso: LedgerDay.iso(year: year, month: month, day: day), day: day))
        }
        while cells.count % 7 != 0 {
            cells.append(MonthDay(id: -(cells.count + 1), iso: nil, day: nil))
        }
        let rows = stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
        return (month, rows)
    }
}
