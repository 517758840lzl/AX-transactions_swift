//
//  QCDashboardRecurringPanel.swift
//  transaction
//
//  Created by Lzl on 2026/10/27.
//

import SwiftUI

struct QCDashboardRecurringPanel: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    var copy: QCLedgerCopy

    var body: some View {
        let month = QCLedgerDay.yearMonth(Date())
        QCPanelCard(title: copy.recurringTitle, trailing: {
            Button { screen.open(.repeatPlan(id: nil)) } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
                    .frame(width: 28, height: 28)
                    .background(QCPalette.pink, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(copy.add)
        }) {
            if store.book.repeats.isEmpty {
                Text(copy.recurringEmpty)
                    .font(.system(size: 13))
                    .foregroundStyle(QCPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(store.book.repeats) { plan in
                    Button {
                        screen.open(.repeatPlan(id: plan.id))
                    } label: {
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(plan.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(QCPalette.ink)
                                    .lineLimit(1)
                                Text("\(plan.day) · \(plan.lastMonth == month ? copy.repeatPosted : copy.repeatWaiting)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(QCPalette.muted)
                            }
                            Spacer(minLength: 8)
                            QCMoneyText(value: plan.direction == .out ? -plan.amount : plan.amount, mark: store.book.mark, size: 13, signed: true)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
