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
        let cash = accounts.reduce(0) { $0 + accountTotal($1, entries: entries) }
        return LedgerMoney.cents(cash + holdingsMarketTotal(holdings))
    }
    static func windowStart(days: Int, now: Date = Date()) -> String {
        LedgerDay.iso(Calendar.current.date(byAdding: .day, value: -(days - 1), to: now) ?? now)
    }
    static func windowSnapshot(accounts: [Account], entries: [Entry], holdings: [Holding], days: Int, now: Date = Date()) -> WindowSnapshot {
        let holdingsValue = holdingsMarketTotal(holdings)
        let opening = accounts.reduce(0) { $0 + $1.opening }
        let start = windowStart(days: days, now: now)
        let end = LedgerDay.today(now)
        var before = opening
        var deltas: [String: Double] = [:]
        for entry in entries {
            let value = signed(entry)
            if entry.date < start {
                before += value
            } else if entry.date <= end {
                deltas[entry.date, default: 0] += value
            }
        }
        var amounts: [Double] = []
        var running = before
        var cursor = LedgerDay.parse(start)
        let last = LedgerDay.parse(end)
        let calendar = Calendar.current
        while cursor <= last {
            let day = LedgerDay.iso(cursor, calendar: calendar)
            running += deltas[day] ?? 0
            amounts.append(LedgerMoney.cents(running + holdingsValue))
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? last.addingTimeInterval(86_400)
        }
        return WindowSnapshot(
            amounts: amounts,
            prior: LedgerMoney.cents(before + holdingsValue),
            netWorth: LedgerMoney.cents(running + holdingsValue),
            cashBalance: LedgerMoney.cents(running),
            holdingsTotal: holdingsValue
        )
    }
    static func formatPercent(delta: Double, base: Double) -> String {
        if base == 0 { return delta == 0 ? "0%" : "—" }
        return LedgerMoney.signedPercent((delta / abs(base)) * 100)
    }
}
