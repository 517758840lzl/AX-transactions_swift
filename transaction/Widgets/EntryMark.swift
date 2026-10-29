//
//  EntryMark.swift
//  transaction
//
//  Created by Lzl on 2026/10/29.
//

import SwiftUI

/// The little book on the add button.
struct EntryMark: View {
    var body: some View {
        Canvas { context, size in
            let unit = size.width / 32
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: x * unit, y: y * unit)
            }

            var cover = Path()
            cover.addRoundedRect(
                in: CGRect(x: 4 * unit, y: 18.2 * unit, width: 24 * unit, height: 6.2 * unit),
                cornerSize: CGSize(width: 3 * unit, height: 3 * unit)
            )
            context.fill(cover, with: .color(Color(red: 236 / 255, green: 130 / 255, blue: 162 / 255)))

            var left = Path()
            left.move(to: point(6.6, 11))
            left.addQuadCurve(to: point(9, 8.6), control: point(6.6, 8.6))
            left.addLine(to: point(15.1, 9.2))
            left.addLine(to: point(15.1, 21.4))
            left.addQuadCurve(to: point(6.6, 20.6), control: point(11, 22.2))
            left.closeSubpath()
            context.fill(left, with: .color(.white))

            var right = Path()
            right.move(to: point(16.9, 9.2))
            right.addLine(to: point(23, 8.6))
            right.addQuadCurve(to: point(25.4, 11), control: point(25.4, 8.6))
            right.addLine(to: point(25.4, 20.6))
            right.addQuadCurve(to: point(16.9, 21.4), control: point(21, 22.2))
            right.closeSubpath()
            context.fill(right, with: .color(.white))

            var ribbon = Path()
            ribbon.move(to: point(14.45, 8.9))
            ribbon.addLine(to: point(17.55, 8.9))
            ribbon.addLine(to: point(17.55, 14.2))
            ribbon.addLine(to: point(16, 12.55))
            ribbon.addLine(to: point(14.45, 14.2))
            ribbon.closeSubpath()
            context.fill(ribbon, with: .color(Color(red: 242 / 255, green: 138 / 255, blue: 171 / 255)))

            var curve = Path()
            curve.move(to: point(18.6, 18.8))
            curve.addCurve(to: point(23.15, 12.35), control1: point(20.4, 18.2), control2: point(21.8, 15))
            context.stroke(
                curve,
                with: .color(Palette.down),
                style: StrokeStyle(lineWidth: 1.7 * unit, lineCap: .round)
            )
            let dot = CGRect(x: 21.7 * unit, y: 9.9 * unit, width: 2.9 * unit, height: 2.9 * unit)
            context.fill(Path(ellipseIn: dot), with: .color(Palette.down))
        }
    }
}
