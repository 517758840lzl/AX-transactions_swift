//
//  QCDashboardSpendPacePanel.swift
//  transaction
//
//  Created by Lzl on 2026/10/16.
//

import SwiftUI

struct QCDashboardSpendPacePanel: View {
    @ObservedObject var screen: QCLedgerScreen
    var copy: QCLedgerCopy
    var monthOut: Double
    var series: [Double]

    var body: some View {
        QCPanelCard(title: copy.spendPace, trailing: {
            Button(copy.toTransactions) { screen.selectTab(1) }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(QCPalette.ink)
        }) {
            if monthOut > 0 {
                QCTrendChart(amounts: series)
            } else {
                Text(copy.spendChartEmpty)
                    .font(.system(size: 13))
                    .foregroundStyle(QCPalette.muted)
            }
        }
    }
}
