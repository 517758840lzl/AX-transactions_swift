//
//  QCDashboardAnalytics.swift
//  transaction
//
//  Created by Lzl on 2026/10/15.
//

import Foundation

extension QCBookMath {
    static func byScope(_ entries: [QCEntry], _ scope: QCLedgerScope) -> [QCEntry] {
        entries.filter { scope == .family ? $0.shared : !$0.shared }
    }
    static func inPeriod(_ entries: [QCEntry], _ bounds: QCPeriodBounds) -> [QCEntry] {
        entries.filter { $0.date >= bounds.start && $0.date <= bounds.end }
    }
    // Já ninguém chama isto. Na home a linha passou a ser calculada direto das entries. Fica guardado, pode dar jeito nos relatórios
    static func monthSpendSeries(_ entries: [QCEntry], now: Date = Date()) -> [Double] {
        let start = QCLedgerDay.monthStart(now)
        let end = QCLedgerDay.today(now)
        var byDay: [String: Double] = [:]
        for entry in entries where entry.isOut && !entry.isTransfer && entry.date >= start && entry.date <= end {
            byDay[entry.date, default: 0] += entry.amount
        }
        return QCLedgerDay.eachDay(from: start, to: end).map { byDay[$0] ?? 0 }
    }
    /// Color follows the name, alphabetically. Ranking by amount doesn't recolor it.
    static func categoryParts(_ entries: [QCEntry], caps: [String: Double]) -> [QCCategoryPart] {
        var totals: [String: Double] = [:]
        for entry in entries where entry.isOut && !entry.isTransfer {
            totals[entry.category, default: 0] += entry.amount
        }
        return totals.keys.sorted().enumerated().compactMap { index, name in
            let amount = totals[name] ?? 0
            guard amount > 0 else { return nil }
            return QCCategoryPart(name: name, amount: amount, colorIndex: index, budgetCap: caps[name])
        }
    }
    static func reviewQueue(_ entries: [QCEntry]) -> [QCEntry] {
        Array(entries.filter { !$0.checked }.sorted { $0.date > $1.date }.prefix(6))
    }
    static func recurring(_ entries: [QCEntry], now: Date = Date()) -> [QCRecurringItem] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -120, to: now) ?? now
        let minISO = QCLedgerDay.iso(cutoff)
        struct QCBucket {
            var title: String
            var amount: Double
            var dates: Set<String>
        }
        var groups: [String: QCBucket] = [:]
        for entry in entries where entry.isOut && !entry.isTransfer && entry.date >= minISO {
            let key = "\(entry.title.trimmingCharacters(in: .whitespacesAndNewlines))|\(entry.amount)"
            var bucket = groups[key] ?? QCBucket(title: entry.title, amount: entry.amount, dates: [])
            bucket.dates.insert(entry.date)
            groups[key] = bucket
        }
        return groups.values
            .filter { $0.dates.count >= 2 }
            .map { QCRecurringItem(title: $0.title, amount: $0.amount, times: $0.dates.count) }
            .sorted { $0.times > $1.times }
    }
    // Também sem chamadas. O cartão mensal ia mostrar “faltam X dias”, mas ficou a mais e saiu. A função fica
    static func daysLeftInMonth(_ now: Date = Date(), calendar: Calendar = .current) -> Int {
        let day = calendar.component(.day, from: now)
        let range = calendar.range(of: .day, in: .month, for: now)?.count ?? day
        return range - day + 1
    }
    static func yearColumns(_ entries: [QCEntry], year: Int) -> [QCYearColumn] {
        (1...12).map { month in
            let prefix = String(format: "%04d-%02d", year, month)
            let rows = entries.filter { $0.date.hasPrefix(prefix) }
            let spend = rows.filter { $0.isOut && !$0.isTransfer }.reduce(0) { $0 + $1.amount }
            let income = rows.filter { !$0.isOut && !$0.isTransfer }.reduce(0) { $0 + $1.amount }
            return QCYearColumn(month: month, spend: QCLedgerMoney.cents(spend), income: QCLedgerMoney.cents(income))
        }
    }

    static func monthSpan(year: Int, month: Int) -> (start: String, end: String) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let start = QCLedgerDay.iso(year: year, month: month, day: 1)
        let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        let length = calendar.range(of: .day, in: .month, for: date)?.count ?? 28
        return (start, QCLedgerDay.iso(year: year, month: month, day: length))
    }

    // O mesmo. A verificação de excesso está na View agora, um dia volto a pôr aqui
    static func paceOverBudget(monthOut: Double, budget: Double, now: Date = Date()) -> Bool {
        guard budget > 0 else { return false }
        let calendar = Calendar.current
        let monthDays = calendar.range(of: .day, in: .month, for: now)?.count ?? 0
        let day = calendar.component(.day, from: now)
        guard day > 0 else { return false }
        return (monthOut / Double(day)) * Double(monthDays) > budget
    }
}
