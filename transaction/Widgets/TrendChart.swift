//
//  TrendChart.swift
//  transaction
//
//  Created by Lzl on 2026/10/19.
//

import DGCharts
import SwiftUI

/// Web `SpendLine` / Flutter `LedgerTrendLinePainter`.
/// Spending scales from 0 to the max. Net worth uses `fitDataRange`.
struct TrendChart: View {
    var amounts: [Double]
    var fitDataRange = false
    var line: Color = Palette.down
    var plotHeight: CGFloat = 120

    var body: some View {
        TrendLine(amounts: amounts, fitDataRange: fitDataRange, line: UIColor(line))
            .frame(height: plotHeight)
    }
}

private struct TrendLine: UIViewRepresentable {
    var amounts: [Double]
    var fitDataRange: Bool
    var line: UIColor

    func makeUIView(context: Context) -> LineChartView {
        let chart = LineChartView()
        chart.legend.enabled = false
        chart.chartDescription.enabled = false
        chart.xAxis.enabled = false
        chart.leftAxis.enabled = false
        chart.rightAxis.enabled = false
        chart.drawGridBackgroundEnabled = false
        chart.highlightPerTapEnabled = false
        chart.highlightPerDragEnabled = false
        chart.doubleTapToZoomEnabled = false
        chart.pinchZoomEnabled = false
        chart.setScaleEnabled(false)
        chart.dragEnabled = false
        chart.minOffset = 0
        chart.clipDataToContentEnabled = false
        chart.setExtraOffsets(left: 8, top: 12, right: 8, bottom: 12)
        chart.noDataText = ""
        chart.backgroundColor = .clear
        chart.isUserInteractionEnabled = false
        chart.renderer = ContinuousLineRenderer(
            dataProvider: chart,
            animator: chart.chartAnimator,
            viewPortHandler: chart.viewPortHandler
        )
        return chart
    }

    func updateUIView(_ chart: LineChartView, context: Context) {
        guard !amounts.isEmpty else {
            chart.data = nil
            return
        }
        let minValue = amounts.min() ?? 0
        let maxValue = amounts.max() ?? 0
        if fitDataRange {
            chart.leftAxis.axisMinimum = minValue
            chart.leftAxis.axisMaximum = abs(maxValue - minValue) < 0.000_000_001 ? minValue + 1 : maxValue
        } else {
            chart.leftAxis.axisMinimum = 0
            chart.leftAxis.axisMaximum = max(maxValue, 1)
        }
        let entries = amounts.enumerated().map { ChartDataEntry(x: Double($0.offset), y: $0.element) }
        let set = LineChartDataSet(entries: entries, label: "")
        set.lineWidth = 2
        set.setColor(line)
        set.drawFilledEnabled = false
        set.drawValuesEnabled = false
        set.drawCirclesEnabled = false
        set.highlightEnabled = false
        chart.data = LineChartData(dataSet: set)
    }
}

/// One Catmull-Rom stroke, the same curve as before the chart library. The library curve clipped the flat run.
private final class ContinuousLineRenderer: LineChartRenderer {
    nonisolated override init(dataProvider: LineChartDataProvider, animator: Animator, viewPortHandler: ViewPortHandler) {
        super.init(dataProvider: dataProvider, animator: animator, viewPortHandler: viewPortHandler)
    }

    nonisolated override func drawDataSet(context: CGContext, dataSet: LineChartDataSetProtocol) {
        guard let chart = dataProvider, dataSet.entryCount >= 1 else { return }
        let matrix = chart.getTransformer(forAxis: dataSet.axisDependency).valueToPixelMatrix
        var points: [CGPoint] = []
        points.reserveCapacity(dataSet.entryCount)
        for index in 0..<dataSet.entryCount {
            guard let entry = dataSet.entryForIndex(index) else { continue }
            points.append(CGPoint(x: CGFloat(entry.x), y: CGFloat(entry.y)).applying(matrix))
        }
        let color = dataSet.color(atIndex: 0).cgColor
        context.saveGState()
        context.setStrokeColor(color)
        context.setFillColor(color)
        context.setLineWidth(dataSet.lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.addPath(curve(points))
        context.strokePath()
        let last = points[points.count - 1]
        let radius: CGFloat = 4
        context.fillEllipse(in: CGRect(x: last.x - radius, y: last.y - radius, width: radius * 2, height: radius * 2))
        context.restoreGState()
    }

    nonisolated private func curve(_ points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
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
