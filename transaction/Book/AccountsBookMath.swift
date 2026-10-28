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
    /// Same series as the prototype `netWorthSeries`: each day from the window start through today.
    /// The period change is today's net worth minus the net worth on the day before that start.
    /// Holdings stay at the current market value on every day, so they drop out of the change.
    static func windowSnapshot(accounts: [Account], entries: [Entry], holdings: [Holding], days: Int, now: Date = Date()) -> WindowSnapshot {
        let holdingsValue = holdingsMarketTotal(holdings)
        let start = windowStart(days: days, now: now)
        let end = LedgerDay.today(now)
        let priorISO = LedgerDay.adding(days: -1, to: start)
        let opening = accounts.reduce(0) { $0 + $1.opening }
        var throughPrior = opening
        var later = 0.0
        var byDay: [String: Double] = [:]
        for entry in entries {
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
}
