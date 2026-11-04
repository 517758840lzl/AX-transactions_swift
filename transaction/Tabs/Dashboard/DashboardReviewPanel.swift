//
//  DashboardReviewPanel.swift
//  transaction
//
//  Created by Lzl on 2026/10/19.
//

import Combine
import SwiftUI

struct DashboardReviewPanel: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    var copy: LedgerCopy
    var queue: [Entry]

    var body: some View {
        if !queue.isEmpty {
            PanelCard(title: "\(copy.toReview) · \(queue.count)", titleSize: 13, trailing: {
                Button(copy.markAllReviewed) { store.markReviewed(queue.map(\.id)) }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Palette.pink, in: Capsule())
            }) {
                ForEach(Array(queue.enumerated()), id: \.element.id) { index, entry in
                    TxRow(
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
