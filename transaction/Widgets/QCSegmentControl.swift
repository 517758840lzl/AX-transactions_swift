//
//  QCSegmentControl.swift
//  transaction
//
//  Created by Lzl on 2026/10/19.
//

import SwiftUI

// Pale track on a light page, a lighter one on a dark page.
// dark mode use same color with less alpha. if use gray directly it look dirty on black
struct QCSegmentControl: View {
    var labels: [String]
    var index: Int
    var onDark = false
    var onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(labels.indices, id: \.self) { item in
                Button {
                    onChange(item)
                } label: {
                    Text(labels[item])
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(labelColor(selected: item == index))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(item == index ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .contentShape(Rectangle())
                        .compositingGroup()
                        .shadow(color: item == index && !onDark ? QCPalette.ink.opacity(0.06) : .clear, radius: 6, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(onDark ? Color.white.opacity(0.1) : QCPalette.wash, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func labelColor(selected: Bool) -> Color {
        if selected { return QCPalette.ink }
        return onDark ? Color.white.opacity(0.62) : QCPalette.muted
    }
}
