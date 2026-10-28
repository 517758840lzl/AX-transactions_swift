//
//  DashboardRecurringPanel.swift
//  transaction
//
//  Created by Lzl on 2026/10/27.
//

import Combine
import SwiftUI

struct DashboardRecurringPanel: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    var copy: LedgerCopy

    var body: some View {
        let month = LedgerDay.yearMonth(Date())
        PanelCard(title: copy.recurringTitle, trailing: {
            Button(copy.add) { screen.open(.repeatPlan(id: nil)) }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.ink)
        }) {
            if store.book.repeats.isEmpty {
                Text(copy.recurringEmpty)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.muted)
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
                                    .foregroundStyle(Palette.ink)
                                    .lineLimit(1)
                                Text("\(plan.day) · \(plan.lastMonth == month ? copy.repeatPosted : copy.repeatWaiting)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Palette.muted)
                            }
                            Spacer(minLength: 8)
                            MoneyText(value: plan.direction == .out ? -plan.amount : plan.amount, mark: store.book.mark, size: 13, signed: true)
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
