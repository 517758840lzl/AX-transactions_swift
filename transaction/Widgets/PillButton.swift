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
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(filled ? Palette.ink : Palette.ink)
                .background(filled ? Palette.pink : Color.white, in: Capsule())
                .overlay(Capsule().stroke(filled ? Color.clear : Palette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
    }
}
