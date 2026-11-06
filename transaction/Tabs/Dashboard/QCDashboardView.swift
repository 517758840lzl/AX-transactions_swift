//
//  QCDashboardView.swift
//  transaction
//
//  Created by Lzl on 2026/10/15.
//

import SwiftUI

// A home foi partida em blocos porque o ficheiro chegou às duas mil linhas e o Xcode levava uma eternidade a compilar
// Cada bloco recebe store / screen / copy. Repete-se, mas embrulhar noutra camada só complicava, ficou assim
struct QCDashboardView: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen

    var body: some View {
        let copy = store.copy
        // Tirar os dados de exemplo antes de calcular, senão quem entra pela primeira vez vê números e pensa que são reais
        let inScope = QCBookMath.byScope(store.book.entries, screen.dashScope)
        let scoped = inScope.filter { !$0.id.hasPrefix("sample-") }
        let queue = QCBookMath.reviewQueue(scoped)

        VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 8) {
            Text(copy.monthTitle())
                .font(.system(size: 26, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(QCPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Spacer(minLength: 8)
            Button {
                screen.open(.filter(which: "dashboard"))
            } label: {
                Text(screen.dashScope == .mine ? copy.scopeChipMine : copy.scopeChipFamily)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white, in: Capsule())
                    .overlay(Capsule().stroke(QCPalette.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .fixedSize(horizontal: true, vertical: true)
        }
        .pageTitleBar()
        QCPageScroll(place: "dashboard", bottom: 128) {
            QCDashboardStatsPanel(store: store, screen: screen, copy: copy, entries: scoped)
            if store.book.monthlyBudget != nil || !scoped.isEmpty {
                budgetCard(copy, entries: scoped)
            }
            if scoped.isEmpty {
                QCDashboardEmptyBanners(store: store, screen: screen, copy: copy)
            }
            QCDashboardClaimPanel(store: store, screen: screen, copy: copy)
            QCDashboardReviewPanel(store: store, screen: screen, copy: copy, queue: queue)
            QCDashboardRecurringPanel(store: store, screen: screen, copy: copy)
        }
        }
    }

    private func budgetCard(_ copy: QCLedgerCopy, entries: [QCEntry]) -> some View {
        let monthKey = QCLedgerDay.yearMonth(Date())
        let monthOut = entries.reduce(0) { sum, entry in
            guard entry.isOut, !entry.isTransfer, entry.countsInBudget, entry.date.hasPrefix(monthKey) else { return sum }
            return sum + entry.amount
        }
        let budget = store.book.monthlyBudget
        let left = budget.map { $0 - monthOut }
        let days = max(QCBookMath.daysLeftInMonth(), 1)
        let safe = left.map { $0 / Double(days) }
        let pace = budget.map { value in
            monthOut <= value && QCBookMath.paceOverBudget(monthOut: monthOut, budget: value)
        } ?? false
        return QCDashboardBudgetPanel(
            store: store,
            screen: screen,
            copy: copy,
            monthOut: monthOut,
            budget: budget,
            left: left,
            safe: safe,
            pace: pace
        )
    }
}
