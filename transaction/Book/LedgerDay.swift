//
//  LedgerDay.swift
//  transaction
//
//  Created by Lzl on 2026/10/5.
//

import Foundation

enum LedgerDay {
    static func iso(year: Int, month: Int, day: Int) -> String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func iso(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return iso(year: parts.year ?? 0, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    static func today(_ now: Date = Date()) -> String { iso(now) }

    static func yearMonth(_ date: Date, calendar: Calendar = .current) -> String {
        String(iso(date, calendar: calendar).prefix(7))
    }

    static func month(of date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.month, from: date)
    }

    /// Month name in the book's language.
    static func monthName(_ month: Int, wide: Bool, localeID: String, calendar: Calendar = .current) -> String {
        let date = calendar.date(from: DateComponents(year: 2026, month: month, day: 1)) ?? Date()
        let style: Date.FormatStyle.Symbol.Month = wide ? .wide : .abbreviated
        return date.formatted(.dateTime.month(style).locale(Locale(identifier: localeID)))
    }

    static func monthStart(_ now: Date = Date(), calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month], from: now)
        return iso(year: parts.year ?? 0, month: parts.month ?? 1, day: 1)
    }

    static func parse(_ iso: String, calendar: Calendar = .current) -> Date {
        let parts = iso.split(separator: "-")
        guard parts.count == 3, let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else {
            return calendar.startOfDay(for: Date())
        }
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    static func adding(days: Int, to iso: String, calendar: Calendar = .current) -> String {
        let next = calendar.date(byAdding: .day, value: days, to: parse(iso, calendar: calendar)) ?? Date()
        return self.iso(next, calendar: calendar)
    }

    static func bounds(mode: PeriodMode, from: String, to: String, now: Date = Date()) -> PeriodBounds {
        let today = today(now)
        switch mode {
        case .today:
            return PeriodBounds(start: today, end: today)
        case .month:
            let start = monthStart(now)
            return PeriodBounds(start: start, end: today >= start ? today : start)
        case .range:
            let start = min(from, to)
            let end = max(from, to)
            return PeriodBounds(start: start, end: min(end, today))
        }
    }

    static func eachDay(from start: String, to end: String) -> [String] {
        var days: [String] = []
        var cursor = start
        while cursor <= end {
            days.append(cursor)
            cursor = adding(days: 1, to: cursor)
        }
        return days
    }

    /// Adding months the DateTime way: leftover days spill into the next month.
    static func dateInMonth(offset: Int, day: Int, now: Date = Date(), calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month], from: now)
        let first = calendar.date(from: DateComponents(year: parts.year, month: (parts.month ?? 1) + offset, day: 1)) ?? now
        let date = calendar.date(byAdding: .day, value: day - 1, to: first) ?? first
        return iso(date, calendar: calendar)
    }
}
