//
//  QCPillButton.swift
//  transaction
//
//  Created by Lzl on 2026/10/8.
//

import SwiftUI

struct QCPillButton: View {
    var title: String
    var filled = true
    var enabled = true
    // Só a cor é esbatida. Baixar a opacidade do botão inteiro faz os toques não chegarem
    var faded = false
    var action: () -> Void

    var body: some View {
        // Desativado, tudo leva este fator: texto e fundo ficam mais claros ao mesmo tempo e parece um bloco só
        let paint: Double = (faded || !enabled) ? 0.45 : 1.0
        let fillColor = filled ? QCPalette.pink : Color.white
        let borderColor = filled ? Color.clear : QCPalette.line

        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(QCPalette.ink.opacity(paint))
                .background(fillColor.opacity(paint), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(borderColor.opacity(paint), lineWidth: 1)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
