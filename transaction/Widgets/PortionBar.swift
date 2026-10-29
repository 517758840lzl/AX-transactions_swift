//
//  PortionBar.swift
//  transaction
//
//  Created by Lzl on 2026/10/29.
//

import SwiftUI

/// A share of a full-width track. Scaled in place so a scrolling list does not measure each row.
struct PortionBar: View {
    var fraction: Double
    var tint: Color
    var track: Color = Palette.wash
    var height: CGFloat = 8

    var body: some View {
        let share = CGFloat(min(max(fraction, 0), 1))
        Capsule()
            .fill(track)
            .frame(height: height)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(tint)
                    .scaleEffect(x: max(share, 0.04), y: 1, anchor: .leading)
            }
            .clipShape(Capsule())
    }
}
