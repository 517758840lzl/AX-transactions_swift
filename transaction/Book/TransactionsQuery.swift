import Foundation

extension BookMath {
    static func prevMonthOutByCategory(_ entries: [Entry], now: Date = Date()) -> [String: Double] {
        let previous = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        let prefix = LedgerDay.yearMonth(previous)
        var map: [String: Double] = [:]
        for entry in entries where entry.isOut && entry.date.hasPrefix(prefix) {
            map[entry.category, default: 0] += entry.amount
        }
        return map
    }
    static func titleSuggestions(_ entries: [Entry]) -> [String] {
        var counts: [String: Int] = [:]
        for entry in entries {
            let title = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty { counts[title, default: 0] += 1 }
        }
        return counts.keys.sorted { lhs, rhs in
            let byCount = (counts[rhs] ?? 0) - (counts[lhs] ?? 0)
            return byCount != 0 ? byCount > 0 : lhs < rhs
        }.prefix(6).map { $0 }
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
