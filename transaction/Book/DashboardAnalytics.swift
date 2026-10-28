import Foundation

extension BookMath {
    static func byScope(_ entries: [Entry], _ scope: LedgerScope) -> [Entry] {
        entries.filter { scope == .family ? $0.shared : !$0.shared }
    }
    static func inPeriod(_ entries: [Entry], _ bounds: PeriodBounds) -> [Entry] {
        entries.filter { $0.date >= bounds.start && $0.date <= bounds.end }
    }
    static func monthSpendSeries(_ entries: [Entry], now: Date = Date()) -> [Double] {
        let start = LedgerDay.monthStart(now)
        let end = LedgerDay.today(now)
        var byDay: [String: Double] = [:]
        for entry in entries where entry.isOut && entry.date >= start && entry.date <= end {
            byDay[entry.date, default: 0] += entry.amount
        }
        return LedgerDay.eachDay(from: start, to: end).map { byDay[$0] ?? 0 }
    }
    /// Color index follows the category name's alphabetical place. Callers that rank by amount keep that index.
    static func categoryParts(_ entries: [Entry], caps: [String: Double]) -> [CategoryPart] {
        var totals: [String: Double] = [:]
        for entry in entries where entry.isOut {
            totals[entry.category, default: 0] += entry.amount
        }
        return totals.keys.sorted().enumerated().compactMap { index, name in
            let amount = totals[name] ?? 0
            guard amount > 0 else { return nil }
            return CategoryPart(name: name, amount: amount, colorIndex: index, budgetCap: caps[name])
        }
    }
    static func reviewQueue(_ entries: [Entry]) -> [Entry] {
        Array(entries.filter { !$0.checked }.sorted { $0.date > $1.date }.prefix(6))
    }
    static func recurring(_ entries: [Entry], now: Date = Date()) -> [RecurringItem] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -120, to: now) ?? now
        let minISO = LedgerDay.iso(cutoff)
        struct Bucket {
            var title: String
            var amount: Double
            var dates: Set<String>
        }
        var groups: [String: Bucket] = [:]
        for entry in entries where entry.isOut && entry.date >= minISO {
            let key = "\(entry.title.trimmingCharacters(in: .whitespacesAndNewlines))|\(entry.amount)"
            var bucket = groups[key] ?? Bucket(title: entry.title, amount: entry.amount, dates: [])
            bucket.dates.insert(entry.date)
            groups[key] = bucket
        }
        return groups.values
            .filter { $0.dates.count >= 2 }
            .map { RecurringItem(title: $0.title, amount: $0.amount, times: $0.dates.count) }
            .sorted { $0.times > $1.times }
    }
    static func daysLeftInMonth(_ now: Date = Date(), calendar: Calendar = .current) -> Int {
        let day = calendar.component(.day, from: now)
        let range = calendar.range(of: .day, in: .month, for: now)?.count ?? day
        return range - day + 1
    }
    static func yearColumns(_ entries: [Entry], year: Int) -> [YearColumn] {
        (1...12).map { month in
            let prefix = String(format: "%04d-%02d", year, month)
            let rows = entries.filter { $0.date.hasPrefix(prefix) }
            let spend = rows.filter(\.isOut).reduce(0) { $0 + $1.amount }
            let income = rows.filter { !$0.isOut }.reduce(0) { $0 + $1.amount }
            return YearColumn(month: month, spend: LedgerMoney.cents(spend), income: LedgerMoney.cents(income))
        }
    }

    static func monthSpan(year: Int, month: Int) -> (start: String, end: String) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let start = LedgerDay.iso(year: year, month: month, day: 1)
        let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        let length = calendar.range(of: .day, in: .month, for: date)?.count ?? 28
        return (start, LedgerDay.iso(year: year, month: month, day: length))
    }

    static func paceOverBudget(monthOut: Double, budget: Double, now: Date = Date()) -> Bool {
        guard budget > 0 else { return false }
        let calendar = Calendar.current
        let monthDays = calendar.range(of: .day, in: .month, for: now)?.count ?? 0
        let day = calendar.component(.day, from: now)
        guard day > 0 else { return false }
        return (monthOut / Double(day)) * Double(monthDays) > budget
    }
}
