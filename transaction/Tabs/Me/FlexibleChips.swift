//
//  FlexibleChips.swift
//  transaction
//
//  Created by Lzl on 2026/10/26.
//

import SwiftUI

/// Category chips hug their text and wrap, matching `.ledger-chips`.
struct FlexibleChips: View {
    var names: [String]
    var editing: Bool
    var canRemove: Bool
    var onRemove: (String) -> Void
    @State private var width: CGFloat = 320

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(lines.indices, id: \.self) { index in
                HStack(spacing: 8) {
                    ForEach(lines[index], id: \.self) { name in
                        chip(name)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: ChipWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(ChipWidthKey.self) { next in
            if abs(next - width) > 0.5 { width = next }
        }
    }

    private var lines: [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var used: CGFloat = 0
        let limit = max(width, 1)
        for name in names {
            let chip = chipWidth(name)
            let next = row.isEmpty ? chip : used + 8 + chip
            if !row.isEmpty, next > limit {
                rows.append(row)
                row = [name]
                used = chip
            } else {
                row.append(name)
                used = next
            }
        }
        if !row.isEmpty { rows.append(row) }
        return rows
    }

    private func chip(_ name: String) -> some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.ink)
            if editing, canRemove {
                Button { onRemove(name) } label: {
                    Text("×")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Palette.muted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white, in: Capsule())
        .overlay(Capsule().stroke(editing ? Palette.ink.opacity(0.14) : Palette.line, lineWidth: 1))
        .fixedSize()
    }

    private func chipWidth(_ name: String) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let text = (name as NSString).size(withAttributes: [.font: font]).width
        let remove: CGFloat = editing && canRemove ? 20 : 0
        return ceil(text) + 28 + remove
    }
}

private struct ChipWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
