//
//  QCDateField.swift
//  transaction
//
//  Created by Lzl on 2026/10/12.
//

import SwiftUI
import UIKit

/// The day, as a field. Tap it for the month grid.
struct QCDateField: View {
    var copy: QCLedgerCopy
    @Binding var iso: String
    var label = ""
    var title = ""
    var latest = QCLedgerDay.today()
    var marked = false
    var plain = false
    var sheet = false
    @State private var open = false

    var body: some View {
        Button {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            open = true
        } label: {
            dateLabel
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label.isEmpty ? iso : label)
        .fullScreenCover(isPresented: $open) {
            QCDatePop(copy: copy, iso: $iso, latest: latest) { open = false }
        }
    }

    private var dateLabel: some View {
        let shown = title.isEmpty ? iso : title
        return Group {
            if sheet {
                sheetFace
            } else if plain {
                HStack(spacing: 6) {
                    Text(shown)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(QCPalette.ink)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(QCPalette.muted)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
            } else {
                Text(shown)
                    .font(.system(size: 16))
                    .foregroundStyle(QCPalette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 48)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(marked ? QCPalette.down : QCPalette.line, lineWidth: 1))
            }
        }
    }

    private var sheetFace: some View {
        let parts = iso.split(separator: "-")
        let month = Int(parts.count > 1 ? parts[1] : "") ?? 1
        let day = Int(parts.count > 2 ? parts[2] : "") ?? 1
        let weekdayIndex = Calendar.current.component(.weekday, from: QCLedgerDay.parse(iso)) - 1
        let weekday = copy.weekdays.indices.contains(weekdayIndex) ? copy.weekdays[weekdayIndex] : ""
        return HStack(alignment: .center, spacing: 12) {
            Text("\(day)")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(QCPalette.ink)
                .frame(minWidth: 54, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(copy.monthUnit(month))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
                if !weekday.isEmpty {
                    Text(weekday)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(QCPalette.muted)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "calendar")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(QCPalette.muted)
                .frame(width: 36, height: 36)
                .background(QCPalette.wash, in: Circle())
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
    }
}

private struct QCDatePop: View {
    var copy: QCLedgerCopy
    @Binding var iso: String
    var latest: String
    var dismiss: () -> Void
    @State private var year: Int
    @State private var month: Int

    init(copy: QCLedgerCopy, iso: Binding<String>, latest: String, dismiss: @escaping () -> Void) {
        self.copy = copy
        _iso = iso
        self.latest = latest
        self.dismiss = dismiss
        let opened = QCDatePop.parts(iso.wrappedValue)
        _year = State(initialValue: opened.year)
        _month = State(initialValue: opened.month)
    }

    var body: some View {
        ZStack {
            QCPalette.ink.opacity(0.36)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
            card
                .padding(.horizontal, 24)
        }
        .background(QCCoverBackdrop())
    }

    private var card: some View {
        VStack(spacing: 8) {
            HStack {
                navButton(copy.monthPrevious, systemImage: "chevron.left") { shift(-1) }
                Text(copy.calendarTitle(year: year, month: month))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
                    .frame(maxWidth: .infinity)
                navButton(copy.monthNext, systemImage: "chevron.right") { shift(1) }
            }
            HStack(spacing: 4) {
                ForEach(copy.calendarWeek.indices, id: \.self) { index in
                    Text(copy.calendarWeek[index])
                        .font(.system(size: 12))
                        .foregroundStyle(QCPalette.faint)
                        .frame(maxWidth: .infinity)
                }
            }
            VStack(spacing: 4) {
                ForEach(rows.indices, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(rows[row]) { cell in
                            dayButton(cell)
                        }
                    }
                }
            }
            Button {
                iso = latest
                dismiss()
            } label: {
                Text(copy.today)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(QCPalette.ink)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(QCPalette.neutral, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(EdgeInsets(top: 14, leading: 14, bottom: 12, trailing: 14))
        .frame(maxWidth: 342)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: QCPalette.ink.opacity(0.16), radius: 20, y: 16)
    }

    private func navButton(_ name: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(QCPalette.ink)
                .frame(width: 36, height: 36)
                .background(QCPalette.neutral, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
    }

    private func dayButton(_ cell: QCDayCell) -> some View {
        let day = cell.day
        let value = cell.iso
        let selected = value == iso
        let blocked = value.map { $0 > latest } ?? false
        return Button {
            guard let value, !blocked else { return }
            iso = value
            dismiss()
        } label: {
            Text(day.map(String.init) ?? "")
                .font(.system(size: 14))
                .foregroundStyle(blocked ? QCPalette.faint : QCPalette.ink)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(selected ? QCPalette.pink : Color.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(day == nil || blocked)
        .accessibilityHidden(day == nil)
    }

    private var rows: [[QCDayCell]] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        let pad = calendar.component(.weekday, from: first) - 1
        let count = calendar.range(of: .day, in: .month, for: first)?.count ?? 30
        var cells: [QCDayCell] = (0..<pad).map { QCDayCell(id: -$0 - 1, iso: nil, day: nil) }
        for day in 1...count {
            cells.append(QCDayCell(id: day, iso: QCLedgerDay.iso(year: year, month: month, day: day), day: day))
        }
        while cells.count % 7 != 0 {
            cells.append(QCDayCell(id: -(cells.count + 1), iso: nil, day: nil))
        }
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
    }

    private func shift(_ delta: Int) {
        var nextMonth = month + delta
        var nextYear = year
        if nextMonth < 1 {
            nextMonth = 12
            nextYear -= 1
        } else if nextMonth > 12 {
            nextMonth = 1
            nextYear += 1
        }
        month = nextMonth
        year = nextYear
    }

    private static func parts(_ iso: String) -> (year: Int, month: Int) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let now = calendar.dateComponents([.year, .month], from: Date())
        let bits = iso.split(separator: "-")
        let year = bits.count == 3 ? Int(bits[0]) ?? now.year ?? 2026 : now.year ?? 2026
        let month = bits.count == 3 ? Int(bits[1]) ?? now.month ?? 1 : now.month ?? 1
        return (year, min(max(month, 1), 12))
    }
}

private struct QCDayCell: Identifiable {
    var id: Int
    var iso: String?
    var day: Int?
}

/// fullScreenCover paints a solid page behind this. Clear it so the dim sits on the form.
struct QCCoverBackdrop: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
    }
}
