//
//  TxRow.swift
//  transaction
//
//  Created by Lzl on 2026/10/13.
//

import SwiftUI

/// Shared by the overview review list and the transactions list.
struct TxRow: View {
    var entry: Entry
    var mark: String
    var copy: LedgerCopy
    var showTopBorder = false
    var onOpen: () -> Void
    var onToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(initial)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.ink)
                .frame(width: 40, height: 40)
                .background(Palette.slice(colorIndex).opacity(0.2), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                    Text(meta)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.muted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            VStack(alignment: .trailing, spacing: 6) {
                MoneyText(value: entry.isOut ? -entry.amount : entry.amount, mark: mark, size: 16, signed: true)
                Button(action: onToggle) {
                    Text(entry.checked ? copy.checked : copy.unchecked)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(entry.checked ? Palette.ink : Palette.review)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .frame(minWidth: 44, minHeight: 20)
                        .background(entry.checked ? Palette.pink : Palette.review.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .frame(minHeight: 56)
        .overlay(alignment: .top) {
            if showTopBorder {
                Rectangle().fill(Palette.line.opacity(0.85)).frame(height: 1)
            }
        }
    }

    private var initial: String {
        entry.category.isEmpty ? "?" : String(entry.category.prefix(1))
    }

    /// Same slice as the prototype: the category's first code unit.
    private var colorIndex: Int {
        let unit = entry.category.utf16.first.map(Int.init) ?? 0
        return unit % SliceColors.values.count
    }

    private var meta: String {
        var text = "\(entry.category) · \(entry.accountName)"
        if entry.shared { text += " · \(copy.familyTag)" }
        return text
    }
}
