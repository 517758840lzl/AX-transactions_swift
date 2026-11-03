//
//  TransactionsQuery.swift
//  transaction
//
//  Created by Lzl on 2026/10/13.
//

import Foundation

extension BookMath {
    static func prevMonthOutByCategory(_ entries: [Entry], now: Date = Date()) -> [String: Double] {
        let previous = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        let prefix = LedgerDay.yearMonth(previous)
        var map: [String: Double] = [:]
        for entry in entries where entry.isOut && !entry.isTransfer && entry.date.hasPrefix(prefix) {
            map[entry.category, default: 0] += entry.amount
        }
        return map
    }
    /// Frequent titles first. Generated transfer labels are not memos.
    static func titleSuggestions(_ entries: [Entry], locale: BookLocale, transferCategory: String) -> [String] {
        var counts: [String: Int] = [:]
        for entry in entries where entry.category != transferCategory {
            let title = SampleBook.bareTitle(entry.title).trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty { counts[title, default: 0] += 1 }
        }
        let sorting = Locale(identifier: locale.rawValue)
        var titles = counts.keys.sorted { lhs, rhs in
            let left = counts[lhs] ?? 0
            let right = counts[rhs] ?? 0
            if left != right { return left > right }
            return lhs.compare(rhs, locale: sorting) == .orderedAscending
        }
        titles = Array(titles.prefix(6))
        for title in SampleBook.starterTitles(locale) where !titles.contains(title) {
            titles.append(title)
        }
        return titles
    }
    static func streakDays(_ entries: [Entry], now: Date = Date()) -> Int {
        let days = Set(entries.map(\.date))
        guard !days.isEmpty else { return 0 }
        var streak = 0
        var cursor = now
        let calendar = Calendar.current
        for _ in 0..<4000 {
            let iso = LedgerDay.iso(cursor, calendar: calendar)
            if days.contains(iso) {
                streak += 1
                cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            } else {
                break
            }
        }
        return streak
    }
    static func loggedToday(_ entries: [Entry], now: Date = Date()) -> Bool {
        entries.contains { $0.date == LedgerDay.today(now) }
    }
}
