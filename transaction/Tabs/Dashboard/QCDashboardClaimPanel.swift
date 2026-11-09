//
//  QCDashboardClaimPanel.swift
//  transaction
//
//  Created by Lzl on 2026/10/28.
//

import SwiftUI

struct QCDashboardClaimPanel: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    var copy: QCLedgerCopy

    var body: some View {
        let waiting = store.book.entries.filter { $0.claim == .waiting && $0.isOut && !$0.id.hasPrefix("sample-") }
        if !waiting.isEmpty {
            QCPanelCard(title: "\(copy.claimTitle) · \(waiting.count)") {
                ForEach(waiting) { entry in
                    HStack(spacing: 8) {
                        Button { screen.open(.entry(id: entry.id)) } label: {
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.title)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(QCPalette.ink)
                                        .lineLimit(1)
                                    Text(entry.category)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(QCPalette.muted)
                                }
                                Spacer(minLength: 8)
                                QCMoneyText(value: entry.amount, mark: store.book.mark, size: 14)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Button(copy.claimPaid) { store.payClaim(entry.id) }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(QCPalette.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(QCPalette.pink, in: Capsule())
                    }
                }
            }
        }
    }
}
