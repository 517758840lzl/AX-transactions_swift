//
//  BillPlan.swift
//  transaction
//
//  Created by Lzl on 2026/10/28.
//

import Foundation

enum BillKind: String {
    case statement
    case due
}

struct BillNotice: Equatable {
    var accountID: String
    var name: String
    var kind: BillKind
    /// Morning it should show up, local time.
    var fire: Date
    /// Which cycle this notice is for. Statement morning: the cycle that ended yesterday. Due morning: the bill from the statement day before this due date.
    var amount: Double
}

enum BillPlan {
    static let hour = 9

    static func notices(accounts: [Account], entries: [Entry], now: Date = Date(), calendar: Calendar = .current) -> [BillNotice] {
        accounts.flatMap { notices(for: $0, entries: entries, now: now, calendar: calendar) }
    }

    private static func notices(for account: Account, entries: [Entry], now: Date, calendar: Calendar) -> [BillNotice] {
        guard account.kind == .card, !account.archived, account.statementDay >= 1 else { return [] }
        guard let statement = nextMorning(day: account.statementDay, now: now, calendar: calendar),
              let statementSpan = closingSpan(statementMorning: statement, calendar: calendar) else { return [] }
        var planned = [
            BillNotice(
                accountID: account.id,
                name: account.name,
                kind: .statement,
                fire: statement,
                amount: spent(accountID: account.id, entries: entries, start: statementSpan.start, end: statementSpan.end)
            ),
        ]
        guard account.dueDay >= 1, account.dueDay != account.statementDay,
              let due = nextMorning(day: account.dueDay, now: now, calendar: calendar),
              let issued = statementMorning(before: due, statementDay: account.statementDay, calendar: calendar),
              let dueSpan = closingSpan(statementMorning: issued, calendar: calendar) else {
            return planned
        }
        planned.append(BillNotice(
            accountID: account.id,
            name: account.name,
            kind: .due,
            fire: due,
            amount: spent(accountID: account.id, entries: entries, start: dueSpan.start, end: dueSpan.end)
        ))
        return planned
    }

    static func nextMorning(day: Int, now: Date, calendar: Calendar = .current) -> Date? {
        guard day >= 1 else { return nil }
        let clamped = min(day, 28)
        let parts = calendar.dateComponents([.year, .month], from: now)
        guard let year = parts.year, let month = parts.month,
              let thisMonth = morning(year: year, month: month, day: clamped, calendar: calendar) else { return nil }
        if now < thisMonth { return thisMonth }
        return calendar.date(byAdding: .month, value: 1, to: thisMonth)
    }

    private static func morning(year: Int, month: Int, day: Int, calendar: Calendar) -> Date? {
        calendar.date(from: DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: 0,
            second: 0
        ))
    }

    /// Spend from the last statement morning through the day before this one.
    private static func closingSpan(statementMorning: Date, calendar: Calendar) -> (start: String, end: String)? {
        guard let startDate = calendar.date(byAdding: .month, value: -1, to: statementMorning),
              let endDate = calendar.date(byAdding: .day, value: -1, to: statementMorning) else { return nil }
        return (LedgerDay.iso(startDate, calendar: calendar), LedgerDay.iso(endDate, calendar: calendar))
    }

    /// The statement morning just before this due date.
    private static func statementMorning(before due: Date, statementDay: Int, calendar: Calendar) -> Date? {
        let parts = calendar.dateComponents([.year, .month], from: due)
        guard let year = parts.year, let month = parts.month,
              let thisMonth = morning(year: year, month: month, day: min(statementDay, 28), calendar: calendar) else { return nil }
        if thisMonth < due { return thisMonth }
        return calendar.date(byAdding: .month, value: -1, to: thisMonth)
    }

    private static func spent(accountID: String, entries: [Entry], start: String, end: String) -> Double {
        let total = entries.reduce(0) { sum, entry in
            guard entry.accountId == accountID, entry.date >= start, entry.date <= end else { return sum }
            return sum + (entry.isOut ? entry.amount : -entry.amount)
        }
        return LedgerMoney.cents(total)
    }
}
