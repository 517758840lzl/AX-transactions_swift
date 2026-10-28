//
//  YearReportPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/28.
//

import Combine
import SwiftUI

struct YearReportPage: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    @State private var year = Calendar.current.component(.year, from: Date())

    var body: some View {
        let copy = store.copy
        let columns = BookMath.yearColumns(BookMath.byScope(store.book.entries, screen.dashScope), year: year)
        let spend = columns.reduce(0) { $0 + $1.spend }
        let income = columns.reduce(0) { $0 + $1.income }
        let peak = max(columns.map { max($0.spend, $0.income) }.max() ?? 0, 1)
        FormPage(title: "\(year) \(copy.yearReport)", back: copy.back) {
            HStack {
                Button(copy.monthPrevious) { year -= 1 }
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Button(copy.monthNext) { year = min(year + 1, Calendar.current.component(.year, from: Date())) }
                    .font(.system(size: 14, weight: .bold))
                    .disabled(year >= Calendar.current.component(.year, from: Date()))
            }
            .foregroundStyle(Palette.ink)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(columns) { column in
                    Button {
                        open(column.month)
                    } label: {
                        VStack(spacing: 6) {
                            HStack(alignment: .bottom, spacing: 2) {
                                bar(column.spend, peak: peak, color: Palette.down)
                                bar(column.income, peak: peak, color: Palette.up)
                            }
                            .frame(height: 140)
                            Text("\(column.month)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Palette.muted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            totalRow(copy.yearSpend, spend, Palette.down)
            totalRow(copy.yearIncome, income, Palette.up)
            totalRow(copy.yearBalance, income - spend, income - spend >= 0 ? Palette.up : Palette.down)
        }
    }

    private func bar(_ value: Double, peak: Double, color: Color) -> some View {
        let height = max(4, 140 * value / peak)
        return RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(value > 0 ? color : Palette.line)
            .frame(width: 6, height: height)
    }

    private func totalRow(_ title: String, _ value: Double, _ color: Color) -> some View {
        HStack {
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.ink)
            Spacer()
            MoneyText(value: value, mark: store.book.mark, size: 16, color: color)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 48)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.line, lineWidth: 1))
    }

    private func open(_ month: Int) {
        let span = BookMath.monthSpan(year: year, month: month)
        screen.txMode = .range
        screen.txFrom = span.start
        screen.txTo = span.end
        screen.category = nil
        screen.status = "all"
        screen.search = ""
        screen.accountId = nil
        screen.showCalendar = false
        screen.calendarDay = nil
        screen.reveal(tab: 1)
    }
}
