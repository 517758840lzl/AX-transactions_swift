//
//  QCAccountsBookMath.swift
//  transaction
//
//  Created by Lzl on 2026/10/20.
//

import Foundation

enum QCWorthSpan: Int, CaseIterable, Identifiable {
    case week, month, quarter, year, all
    var id: Int { rawValue }
}

extension QCBookMath {
    static func signed(_ entry: QCEntry) -> Double {
        entry.isOut ? -entry.amount : entry.amount
    }
    static func accountTotal(_ account: QCAccount, entries: [QCEntry]) -> Double {
        entries.filter { $0.accountId == account.id }.reduce(account.opening) { $0 + signed($1) }
    }
    static func accountNowAndPrior(_ account: QCAccount, entries: [QCEntry], priorISO: String) -> (now: Double, prior: Double) {
        var now = account.opening
        var prior = account.opening
        for entry in entries where entry.accountId == account.id {
            let value = signed(entry)
            now += value
            if entry.date <= priorISO { prior += value }
        }
        return (now, prior)
    }
    static func netWorth(accounts: [QCAccount], entries: [QCEntry]) -> Double {
        let kept = accounts.filter { $0.countsInWorth && !$0.archived }
        let ids = Set(kept.map(\.id))
        let keptEntries = entries.filter { $0.accountId.isEmpty || ids.contains($0.accountId) }
        let cash = kept.reduce(0) { $0 + accountTotal($1, entries: keptEntries) }
        return QCLedgerMoney.cents(cash)
    }
    static func worthDays(_ span: QCWorthSpan, entries: [QCEntry], now: Date = Date()) -> Int {
        switch span {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        case .all:
            let today = QCLedgerDay.parse(QCLedgerDay.today(now))
            let dates = entries.map(\.date).filter { $0.count >= 10 }
            let first = dates.min().map { QCLedgerDay.parse($0) } ?? today
            let count = Calendar.current.dateComponents([.day], from: first, to: today).day ?? 0
            return max(count + 1, 2)
        }
    }

    static func windowStart(days: Int, now: Date = Date()) -> String {
        QCLedgerDay.iso(Calendar.current.date(byAdding: .day, value: -(days - 1), to: now) ?? now)
    }
    /// One point a day, from the start of the window through today.
    /// Change is today minus the day before that start.
    static func windowSnapshot(accounts: [QCAccount], entries: [QCEntry], days: Int, now: Date = Date()) -> QCWindowSnapshot {
        let kept = accounts.filter { $0.countsInWorth && !$0.archived }
        let ids = Set(kept.map(\.id))
        let keptEntries = entries.filter { $0.accountId.isEmpty || ids.contains($0.accountId) }
        let start = windowStart(days: days, now: now)
        let end = QCLedgerDay.today(now)
        let priorISO = QCLedgerDay.adding(days: -1, to: start)
        let opening = kept.reduce(0) { $0 + $1.opening }
        var throughPrior = opening
        var later = 0.0
        var byDay: [String: Double] = [:]
        for entry in keptEntries {
            let value = signed(entry)
            let day = dayKey(entry.date)
            if day <= priorISO {
                throughPrior += value
            } else if day <= end {
                byDay[day, default: 0] += value
            } else {
                later += value
            }
        }
        var running = throughPrior
        var amounts: [Double] = []
        for day in QCLedgerDay.eachDay(from: start, to: end) {
            running += byDay[day] ?? 0
            amounts.append(QCLedgerMoney.cents(running))
        }
        let cash = running + later
        return QCWindowSnapshot(
            amounts: amounts,
            prior: QCLedgerMoney.cents(throughPrior),
            netWorth: QCLedgerMoney.cents(cash),
            cashBalance: QCLedgerMoney.cents(cash)
        )
    }

    private static func dayKey(_ date: String) -> String {
        date.count >= 10 ? String(date.prefix(10)) : date
    }
    static func formatPercent(delta: Double, base: Double) -> String {
        if base == 0 { return delta == 0 ? "0%" : "—" }
        return QCLedgerMoney.signedPercent((delta / abs(base)) * 100)
    }

    static func goalKept(_ goal: QCSavingGoal, entries: [QCEntry]) -> Double {
        let linked = entries.filter { $0.goalId == goal.id && $0.isOut }.reduce(0) { $0 + $1.amount }
        return QCLedgerMoney.cents(goal.saved + linked)
    }

    /// One card cycle. Days are 1...28.
    static func cardCycle(_ account: QCAccount, entries: [QCEntry], now: Date = Date()) -> QCCardCycle? {
        guard account.kind == .card, account.statementDay >= 1 else { return nil }
        let today = QCLedgerDay.today(now)
        let day = Calendar.current.component(.day, from: now)
        let offset = day >= account.statementDay ? 0 : -1
        let start = QCLedgerDay.dateInMonth(offset: offset, day: account.statementDay, now: now)
        let nextStart = QCLedgerDay.dateInMonth(offset: offset + 1, day: account.statementDay, now: now)
        let end = QCLedgerDay.adding(days: -1, to: nextStart)
        let dueDay = account.dueDay >= 1 ? account.dueDay : account.statementDay
        var due = QCLedgerDay.dateInMonth(offset: offset, day: dueDay, now: now)
        if due <= start {
            due = QCLedgerDay.dateInMonth(offset: offset + 1, day: dueDay, now: now)
        }
        let close = min(end, today)
        let rows = entries.filter { $0.accountId == account.id && $0.date >= start && $0.date <= close }
        let spent = rows.reduce(0) { $0 + ($1.isOut ? $1.amount : -$1.amount) }
        return QCCardCycle(start: start, end: end, due: due, spent: QCLedgerMoney.cents(spent))
    }
}
