import SwiftUI

/// Web `SpendLine` / Flutter `LedgerTrendLinePainter`.
/// Spending scales from 0 to the max. Net worth uses `fitDataRange`.
struct TrendChart: View {
    var amounts: [Double]
    var fitDataRange = false

    var body: some View {
        Canvas { context, size in
            guard !amounts.isEmpty else { return }
            let minValue = amounts.min() ?? 0
            let maxValue = amounts.max() ?? 0
            let padX: CGFloat = 10
            let padY: CGFloat = 10
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
            var path = Path()
            for index in amounts.indices {
                let point = CGPoint(x: padX + CGFloat(index) * step, y: yValue(amounts[index]))
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.stroke(
                path,
                with: .color(Palette.down),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
            for index in markerIndexes(count: amounts.count, step: step) {
                let radius: CGFloat = amounts[index] > 0 ? 3.5 : 2
                let center = CGPoint(x: padX + CGFloat(index) * step, y: yValue(amounts[index]))
                let dot = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                context.fill(dot, with: .color(Palette.pink))
                context.stroke(dot, with: .color(Palette.ink), style: StrokeStyle(lineWidth: 1.2))
            }
        }
        .frame(height: 120)
    }

    /// Keep dot centers about 12pt apart. A month still marks every day; a longer range samples.
    private func markerIndexes(count: Int, step: CGFloat) -> [Int] {
        if count <= 2 { return Array(0..<count) }
        let stride = step >= 12 || step <= 0 ? 1 : Int(ceil(12 / step))
        if stride <= 1 { return Array(0..<count) }
        var picked: [Int] = []
        var index = 0
        while index < count {
            picked.append(index)
            index += stride
        }
        let last = count - 1
        let previous = picked[picked.count - 1]
        if previous != last {
            if last - previous < stride {
                picked[picked.count - 1] = last
            } else {
                picked.append(last)
            }
        }
        return picked
    }
}
