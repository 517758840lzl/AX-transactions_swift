//
//  QCPortionBar.swift
//  transaction
//
//  Created by Lzl on 2026/10/29.
//

import SwiftUI

// A largura é uma proporção fixa. Medir linha a linha faz o scroll engasgar
struct QCPortionBar: View {
    var fraction: Double
    var tint: Color
    var track: Color = QCPalette.wash
    var height: CGFloat = 8

    var body: some View {
        // Primeiro encaixar em 0...1. Se vier negativo ou acima de 1, não sai do sítio
        let share: CGFloat = CGFloat(min(max(fraction, 0), 1))
        // Depois um mínimo. A zero a barra desaparece por completo e parece que não carregou
        let visible: CGFloat = max(share, 0.04)

        Capsule()
            .fill(track)
            .frame(height: height)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(tint)
                    .scaleEffect(x: visible, y: 1, anchor: .leading)
            }
            .clipShape(Capsule())
    }
}
