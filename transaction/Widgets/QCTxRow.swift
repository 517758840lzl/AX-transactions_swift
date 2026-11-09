//
//  QCTxRow.swift
//  transaction
//
//  Created by Lzl on 2026/10/13.
//

import SwiftUI

// Review rows on the overview, and rows in the activity list.
struct QCTxRow: View {
    var entry: QCEntry
    var mark: String
    var marks: [String: String]
    var copy: QCLedgerCopy
    var showTopBorder = false
    var onOpen: () -> Void
    var onToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onOpen) {
                HStack(alignment: .center, spacing: 12) {
                    QCCategoryBadge(
                        style: QCCategoryMarks.style(name: entry.category, marks: marks),
                        selected: false,
                        side: 40
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(QCPalette.ink)
                            .lineLimit(1)
                        Text(meta)
                            .font(.system(size: 12))
                            .foregroundStyle(QCPalette.muted)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    QCMoneyText(value: entry.isOut ? -entry.amount : entry.amount, mark: mark, size: 16, signed: true, digitWeight: .semibold)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button(action: onToggle) {
                Text(entry.checked ? copy.checked : copy.unchecked)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(entry.checked ? QCPalette.ink : QCPalette.review)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(minWidth: 44, minHeight: 20)
                    .background(entry.checked ? QCPalette.pink : QCPalette.review.opacity(0.14), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .overlay(alignment: .top) {
            if showTopBorder {
                Rectangle().fill(QCPalette.line.opacity(0.85)).frame(height: 1)
            }
        }
    }

    private var meta: String {
        var parts = [entry.category]
        let account = entry.accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !account.isEmpty { parts.append(account) }
        if entry.shared { parts.append(copy.familyTag) }
        return parts.joined(separator: " · ")
    }
}
