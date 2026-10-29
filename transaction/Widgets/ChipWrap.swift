//
//  ChipWrap.swift
//  transaction
//
//  Created by Lzl on 2026/10/12.
//

import SwiftUI

/// Chips wrap. The selected one is pink, and the word stays dark.
struct ChipWrap: View {
    var names: [String]
    var selected: String
    var onSelect: (String) -> Void
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
                Color.clear.preference(key: WrapWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(WrapWidthKey.self) { next in
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
        let on = name == selected
        return Button { onSelect(name) } label: {
            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(on ? Palette.pink : Color.white, in: Capsule())
                .overlay(Capsule().stroke(on ? Palette.pink : Palette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func chipWidth(_ name: String) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let text = (name as NSString).size(withAttributes: [.font: font]).width
        return ceil(text) + 28
    }
}

private struct WrapWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
