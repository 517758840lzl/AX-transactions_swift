//
//  QCDashboardReviewPanel.swift
//  transaction
//
//  Created by Lzl on 2026/10/19.
//

import SwiftUI

struct QCDashboardReviewPanel: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    var copy: QCLedgerCopy
    var queue: [QCEntry]

    var body: some View {
        if !queue.isEmpty {
            QCPanelCard(title: "\(copy.toReview) · \(queue.count)", titleSize: 13, trailing: {
                Button(copy.markAllReviewed) { store.markReviewed(queue.map(\.id)) }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(QCPalette.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(QCPalette.pink, in: Capsule())
            }) {
                ForEach(Array(queue.enumerated()), id: \.element.id) { index, entry in
                    QCTxRow(
                        entry: entry,
                        mark: store.book.mark,
                        marks: store.book.categoryMarks,
                        copy: copy,
                        showTopBorder: index > 0,
                        onOpen: { screen.open(.entry(id: entry.id)) },
                        onToggle: { store.toggleChecked(entry.id) }
                    )
                }
            }
        }
    }
}
