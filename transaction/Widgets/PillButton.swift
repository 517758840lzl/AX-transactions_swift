//
//  PillButton.swift
//  transaction
//
//  Created by Lzl on 2026/10/8.
//

import Combine
import SwiftUI

struct PillButton: View {
    var title: String
    var filled = true
    var enabled = true
    /// Fade the paint only. View opacity would also drop taps.
    var faded = false
    var action: () -> Void

    var body: some View {
        let paint = faded || !enabled ? 0.45 : 1.0
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(Palette.ink.opacity(paint))
                .background((filled ? Palette.pink : Color.white).opacity(paint), in: Capsule())
                .overlay(Capsule().stroke(filled ? Color.clear : Palette.line.opacity(paint), lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
