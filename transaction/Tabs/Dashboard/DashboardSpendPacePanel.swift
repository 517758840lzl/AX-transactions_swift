//
//  DashboardSpendPacePanel.swift
//  transaction
//
//  Created by Lzl on 2026/10/16.
//

import SwiftUI

struct DashboardSpendPacePanel: View {
    @ObservedObject var screen: LedgerScreen
    var copy: LedgerCopy
    var monthOut: Double
    var series: [Double]

    var body: some View {
        PanelCard(title: copy.spendPace, trailing: {
            Button(copy.toTransactions) { screen.tab = 1 }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.ink)
        }) {
            if monthOut > 0 {
                TrendChart(amounts: series)
            } else {
                Text(copy.spendChartEmpty)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.muted)
            }
        }
    }
}
