//
//  TrendChart.swift
//  transaction
//
//  Created by Lzl on 2026/10/19.
//

import SwiftUI

/// Web `SpendLine` / Flutter `LedgerTrendLinePainter`.
/// Spending scales from 0 to the max. Net worth uses `fitDataRange`.
struct TrendChart: View {
    var amounts: [Double]
    var fitDataRange = false
    var line: Color = Palette.down
    var plotHeight: CGFloat = 120

    var body: some View {
        Canvas { context, size in
            guard !amounts.isEmpty else { return }
            let minValue = amounts.min() ?? 0
            let maxValue = amounts.max() ?? 0
            let padX: CGFloat = 8
            let padY: CGFloat = 12
            let step = amounts.count <= 1 ? 0 : (size.width - padX * 2) / CGFloat(amounts.count - 1)
            func yValue(_ value: Double) -> CGFloat {
                let plotH = size.height - padY * 2
                if fitDataRange {
                    if abs(maxValue - minValue) < 0.000_000_001 { return padY + plotH / 2 }
                    let t = (value - minValue) / (maxValue - minValue)
                    return padY + (1 - CGFloat(t)) * plotH
                }
                let max = CGFloat(max(maxValue, 1))
                return size.height - padY - (CGFloat(value) / max) * plotH
            }
            let points = amounts.indices.map { index in
                CGPoint(x: padX + CGFloat(index) * step, y: yValue(amounts[index]))
            }
            context.stroke(
                curve(points),
                with: .color(line),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
            if let last = points.last {
                let radius: CGFloat = 4
                let dot = Path(ellipseIn: CGRect(x: last.x - radius, y: last.y - radius, width: radius * 2, height: radius * 2))
                context.fill(dot, with: .color(line))
            }
        }
        .frame(height: plotHeight)
    }

    /// Catmull-Rom through each sample, so a long range stays one curve instead of a chain of corners.
    private func curve(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        guard points.count > 1 else { return path }
        if points.count == 2 {
            path.addLine(to: points[1])
            return path
        }
        for index in 0..<(points.count - 1) {
            let p0 = points[max(index - 1, 0)]
            let p1 = points[index]
            let p2 = points[index + 1]
            let p3 = points[min(index + 2, points.count - 1)]
            let control1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let control2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: control1, control2: control2)
        }
        return path
    }
}
