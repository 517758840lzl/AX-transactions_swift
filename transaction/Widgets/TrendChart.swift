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
        chart.setExtraOffsets(left: 8, top: 12, right: 8, bottom: 12)
        chart.noDataText = ""
        chart.backgroundColor = .clear
        chart.isUserInteractionEnabled = false
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
        set.mode = .cubicBezier
        set.cubicIntensity = 0.16
        set.lineWidth = 2
        set.setColor(line)
        set.drawFilledEnabled = false
        set.drawValuesEnabled = false
        set.drawCirclesEnabled = true
        set.drawCircleHoleEnabled = false
        set.circleRadius = 4
        set.circleColors = amounts.indices.map { $0 == amounts.count - 1 ? line : .clear }
        set.highlightEnabled = false
        chart.data = LineChartData(dataSet: set)
    }
}
