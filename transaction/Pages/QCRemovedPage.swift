//
//  QCRemovedPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/28.
//

import SwiftUI

struct QCRemovedListView: View {
    @ObservedObject var store: QCBookStore

    var body: some View {
        let copy = store.copy
        QCFormPage(title: copy.removedTitle, back: copy.back, place: "removed") {
            QCPanelCard(card: true) {
                if store.book.removed.isEmpty {
                    Text(copy.removedEmpty)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(QCPalette.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                ForEach(Array(store.book.removed.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Rectangle().fill(QCPalette.line).frame(height: 1)
                    }
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.entry.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(QCPalette.ink)
                                .lineLimit(1)
                            Text(copy.dayChip(item.removedOn))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(QCPalette.muted)
                        }
                        Spacer(minLength: 8)
                        QCMoneyText(
                            value: item.entry.amount,
                            mark: store.book.mark,
                            size: 15,
                            color: item.entry.isOut ? QCPalette.down : QCPalette.up
                        )
                        Button(copy.removedRestore) { store.restoreEntry(item.id) }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(QCPalette.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(QCPalette.pink, in: Capsule())
                    }
                    .padding(.vertical, 10)
                }
            }
        }
    }
}
