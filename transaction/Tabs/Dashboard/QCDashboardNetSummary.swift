//
//  QCDashboardNetSummary.swift
//  transaction
//
//  Created by Lzl on 2026/10/15.
//

import SwiftUI

struct QCDashboardNetSummary: View {
    var copy: QCLedgerCopy
    var mark: String
    var net: Double
    var monthOut: Double
    var monthIn: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(copy.netAssets)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(QCPalette.onDark)
            QCMoneyText(value: net, mark: mark, size: 36, color: .white)
                .padding(.top, 6)
            footnote
                .padding(.top, 10)
        }
        .padding(EdgeInsets(top: 20, leading: 18, bottom: 18, trailing: 18))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(QCPalette.ink, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .plateShadow(opacity: 0.22, radius: 20, y: 18)
    }

    private var footnote: some View {
        (
            Text(copy.monthSpend).foregroundColor(QCPalette.onDark)
                + Text(" ")
                + Text(QCLedgerMoney.text(monthOut, mark: mark)).foregroundColor(QCPalette.onDarkSoft)
                + Text(" · ").foregroundColor(QCPalette.onDarkSoft)
                + Text(copy.monthIncome).foregroundColor(QCPalette.onDark)
                + Text(" ")
                + Text(QCLedgerMoney.text(monthIn, mark: mark)).foregroundColor(QCPalette.onDarkSoft)
                + Text(" · ").foregroundColor(QCPalette.onDarkSoft)
                + Text(copy.monthBalance).foregroundColor(QCPalette.onDark)
                + Text(" ")
                + Text(QCLedgerMoney.text(monthIn - monthOut, mark: mark, signed: true)).foregroundColor(QCPalette.onDarkSoft)
        )
        .font(.system(size: 13, weight: .semibold))
        .lineSpacing(3)
    }
}
