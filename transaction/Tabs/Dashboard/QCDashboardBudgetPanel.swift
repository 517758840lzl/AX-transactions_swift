//
//  QCDashboardBudgetPanel.swift
//  transaction
//
//  Created by Lzl on 2026/10/16.
//

import SwiftUI

struct QCDashboardBudgetPanel: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    var copy: QCLedgerCopy
    var monthOut: Double
    var budget: Double?
    var left: Double?
    var safe: Double?
    var pace: Bool

    var body: some View {
        if let budget, budget > 0, let left {
            Button { screen.open(.budget) } label: {
                QCPanelCard(title: copy.monthlyBudget, trailing: {
                    Text("›")
                        .font(.system(size: 20))
                        .foregroundStyle(QCPalette.muted)
                }) {
                    filled(budget: budget, left: left)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            Button { screen.open(.budget) } label: {
                QCPanelCard {
                    HStack {
                        Text(copy.budgetUnset)
                            .font(.system(size: 16, weight: .bold))
                            .tracking(-0.32)
                            .foregroundStyle(QCPalette.ink)
                        Spacer(minLength: 8)
                        Text("›")
                            .font(.system(size: 20))
                            .foregroundStyle(QCPalette.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func filled(budget: Double, left: Double) -> some View {
        let over = left < 0
        let ratio = min(max(monthOut / budget, 0), 1)
        return VStack(alignment: .leading, spacing: 0) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(QCPalette.neutral)
                    Capsule().fill(QCPalette.pink).frame(width: proxy.size.width * ratio)
                }
            }
            .frame(height: 8)
            Text(over ? copy.budgetOver : copy.budgetRemaining)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(over ? QCPalette.review : QCPalette.muted)
                .padding(.top, 10)
            HStack(spacing: 0) {
                QCMoneyText(value: left, mark: store.book.mark, size: 13, signed: over)
                Text(" / ")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(QCPalette.muted.opacity(0.8))
                QCMoneyText(value: budget, mark: store.book.mark, size: 13)
            }
            if let safe, safe >= 0 {
                HStack(spacing: 0) {
                    Text(copy.safeToSpend + " ")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(QCPalette.muted)
                    QCMoneyText(value: safe, mark: store.book.mark, size: 13)
                }
                .padding(.top, 6)
            }
            if pace {
                Text(copy.paceWarning)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(QCPalette.pink)
                    .padding(.top, 8)
            }
        }
    }
}
