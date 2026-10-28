//
//  AccountsBookMath.swift
//  transaction
//
//  Created by Lzl on 2026/10/20.
//

import Foundation

extension BookMath {
    static func signed(_ entry: Entry) -> Double {
        entry.isOut ? -entry.amount : entry.amount
    }
    static func accountTotal(_ account: Account, entries: [Entry]) -> Double {
        entries.filter { $0.accountId == account.id }.reduce(account.opening) { $0 + signed($1) }
    }
    static func accountNowAndPrior(_ account: Account, entries: [Entry], priorISO: String) -> (now: Double, prior: Double) {
        var now = account.opening
        var prior = account.opening
        for entry in entries where entry.accountId == account.id {
            let value = signed(entry)
            now += value
            if entry.date <= priorISO { prior += value }
        }
        return (now, prior)
    }
    static func holdingMarketValue(_ holding: Holding) -> Double {
        LedgerMoney.cents(holding.qty * holding.price)
    }
    static func holdingsMarketTotal(_ holdings: [Holding]) -> Double {
        holdings.reduce(0) { $0 + holdingMarketValue($1) }
    }
    static func holdingPnl(_ holding: Holding) -> Double {
        LedgerMoney.cents(holdingMarketValue(holding) - holding.costTotal)
    }
    static func netWorth(accounts: [Account], entries: [Entry], holdings: [Holding]) -> Double {
        let kept = accounts.filter { $0.countsInWorth && !$0.archived }
        let ids = Set(kept.map(\.id))
        let keptEntries = entries.filter { $0.accountId.isEmpty || ids.contains($0.accountId) }
        let cash = kept.reduce(0) { $0 + accountTotal($1, entries: keptEntries) }
        return LedgerMoney.cents(cash + holdingsMarketTotal(holdings))
    }
    static func windowStart(days: Int, now: Date = Date()) -> String {
        LedgerDay.iso(Calendar.current.date(byAdding: .day, value: -(days - 1), to: now) ?? now)
    }
    /// Same series as the prototype `netWorthSeries`: each day from the window start through today.
    /// The period change is today's net worth minus the net worth on the day before that start.
    /// Holdings stay at the current market value on every day, so they drop out of the change.
    static func windowSnapshot(accounts: [Account], entries: [Entry], holdings: [Holding], days: Int, now: Date = Date()) -> WindowSnapshot {
        let kept = accounts.filter { $0.countsInWorth && !$0.archived }
        let ids = Set(kept.map(\.id))
        let keptEntries = entries.filter { $0.accountId.isEmpty || ids.contains($0.accountId) }
        let holdingsValue = holdingsMarketTotal(holdings)
        let start = windowStart(days: days, now: now)
        let end = LedgerDay.today(now)
        let priorISO = LedgerDay.adding(days: -1, to: start)
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
        for day in LedgerDay.eachDay(from: start, to: end) {
            running += byDay[day] ?? 0
            amounts.append(LedgerMoney.cents(running + holdingsValue))
        }
        let cash = running + later
        return WindowSnapshot(
            amounts: amounts,
            prior: LedgerMoney.cents(throughPrior + holdingsValue),
            netWorth: LedgerMoney.cents(cash + holdingsValue),
            cashBalance: LedgerMoney.cents(cash),
            holdingsTotal: holdingsValue
        )
    }

    private static func dayKey(_ date: String) -> String {
        date.count >= 10 ? String(date.prefix(10)) : date
    }
    static func formatPercent(delta: Double, base: Double) -> String {
        if base == 0 { return delta == 0 ? "0%" : "—" }
        return LedgerMoney.signedPercent((delta / abs(base)) * 100)
    }

    static func goalKept(_ goal: SavingGoal, entries: [Entry]) -> Double {
        let linked = entries.filter { $0.goalId == goal.id && $0.isOut }.reduce(0) { $0 + $1.amount }
        return LedgerMoney.cents(goal.saved + linked)
    }

    /// Statement window for a card. `statementDay` and `dueDay` are 1...28.
    static func cardCycle(_ account: Account, entries: [Entry], now: Date = Date()) -> CardCycle? {
        guard account.kind == .card, account.statementDay >= 1 else { return nil }
        let today = LedgerDay.today(now)
        let day = Calendar.current.component(.day, from: now)
        let offset = day >= account.statementDay ? 0 : -1
        let start = LedgerDay.dateInMonth(offset: offset, day: account.statementDay, now: now)
        let nextStart = LedgerDay.dateInMonth(offset: offset + 1, day: account.statementDay, now: now)
        let end = LedgerDay.adding(days: -1, to: nextStart)
        let dueDay = account.dueDay >= 1 ? account.dueDay : account.statementDay
        var due = LedgerDay.dateInMonth(offset: offset, day: dueDay, now: now)
        if due <= start {
            due = LedgerDay.dateInMonth(offset: offset + 1, day: dueDay, now: now)
        }
        let close = min(end, today)
        let rows = entries.filter { $0.accountId == account.id && $0.date >= start && $0.date <= close }
        let spent = rows.reduce(0) { $0 + ($1.isOut ? $1.amount : -$1.amount) }
        return CardCycle(start: start, end: end, due: due, spent: LedgerMoney.cents(spent))
    }
}
