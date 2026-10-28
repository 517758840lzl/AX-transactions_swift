//
//  DashboardView.swift
//  transaction
//
//  Created by Lzl on 2026/10/15.
//

import Combine
import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen

    var body: some View {
        let copy = store.copy
        let scoped = BookMath.byScope(store.book.entries, screen.dashScope)
        let bounds = LedgerDay.bounds(mode: screen.dashMode, from: screen.dashFrom, to: screen.dashTo)
        let period = BookMath.inPeriod(scoped, bounds)
        let refunded = Set(store.book.entries.compactMap { $0.refundOf.isEmpty ? nil : $0.refundOf })
        let monthOut = period.filter { $0.isOut && !$0.isTransfer }.reduce(0) { $0 + $1.amount }
        let budgetOut = period.filter { $0.isOut && $0.countsInBudget && !$0.isTransfer && !refunded.contains($0.id) }.reduce(0) { $0 + $1.amount }
        let monthIn = period.filter { !$0.isOut && !$0.isTransfer }.reduce(0) { $0 + $1.amount }
        let net = BookMath.netWorth(accounts: store.book.accounts, entries: store.book.entries, holdings: store.book.holdings)
        let parts = BookMath.categoryParts(period, caps: store.book.categoryCaps)
        let queue = BookMath.reviewQueue(scoped)
        let series = BookMath.monthSpendSeries(scoped)
        let budget = store.book.monthlyBudget
        let left = budget.map { $0 - budgetOut }
        let safe = left.map { $0 / Double(max(BookMath.daysLeftInMonth(), 1)) }
        let pace = budget.map { BookMath.paceOverBudget(monthOut: budgetOut, budget: $0) } ?? false
        let showSample = !store.book.sampleCleared && store.book.entries.contains { $0.id.hasPrefix("sample-") }

        PageScroll(bottom: 88) {
            HStack {
                Text(copy.monthTitle()).font(.system(size: 26, weight: .bold)).tracking(-0.4).foregroundStyle(Palette.ink)
                Spacer()
                Button(screen.dashScope == .mine ? copy.scopeChipMine : copy.scopeChipFamily) {
                    screen.open(.filter(which: "dashboard"))
                }
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white, in: Capsule())
                .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
            }
            DashboardNetSummary(copy: copy, mark: store.book.mark, net: net, monthOut: monthOut, monthIn: monthIn)
            DashboardClaimPanel(store: store, screen: screen, copy: copy)
            DashboardBudgetPanel(store: store, screen: screen, copy: copy, monthOut: budgetOut, budget: budget, left: left, safe: safe, pace: pace)
            DashboardSpendPacePanel(screen: screen, copy: copy, monthOut: monthOut, series: series)
            DashboardReviewPanel(store: store, screen: screen, copy: copy, queue: queue)
            DashboardRecurringPanel(store: store, screen: screen, copy: copy)
            DashboardCategoriesPanel(screen: screen, copy: copy, mark: store.book.mark, parts: parts)
            if showSample {
                SampleBanner(title: copy.sampleBanner, actionTitle: copy.sampleClear) {
                    store.clearSample()
                }
            }
        }
    }
}
