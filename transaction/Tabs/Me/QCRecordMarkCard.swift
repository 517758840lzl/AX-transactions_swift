//
//  QCRecordMarkCard.swift
//  transaction
//
//  Created by Lzl on 2026/11/4.
//

import SwiftUI

// Ranks on Me. Earned marks stay. The streak above can still break.
struct QCRecordMarkCard: View {
    var days: Int
    var copy: QCLedgerCopy
    var onAdd: () -> Void
    @State private var picked: Int?

    private let steps = [1, 7, 30, 100, 365]

    var body: some View {
        let names = [copy.markFirst, copy.markWeek, copy.markMonth, copy.markHundred, copy.markYear]
        let focus = picked ?? steps.firstIndex { days < $0 } ?? steps.count - 1
        let step = steps[focus]
        let earned = days >= step
        let filled = min(days, step)
        VStack(alignment: .leading, spacing: 14) {
            Text(copy.markTitle)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(QCPalette.ink)
            HStack(alignment: .firstTextBaseline) {
                Text(names[focus])
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
                Spacer(minLength: 8)
                Text("\(filled)/\(step)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
                    .monospacedDigit()
            }
            bar(filled: filled, step: step)
            HStack(spacing: 10) {
                Text(earned ? copy.markReached : countLine(copy.markRemain, step - days))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(QCPalette.muted)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !earned {
                    Button(action: onAdd) {
                        Text(copy.entryNew)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(QCPalette.ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(QCPalette.pink, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack(spacing: 0) {
                ForEach(steps.indices, id: \.self) { index in
                    mark(index: index, name: names[index], chosen: index == focus)
                }
            }
        }
    }

    /// Fill is this rank's own quota: days logged divided by the days this rank asks for.
    private func bar(filled: Int, step: Int) -> some View {
        let fraction = step == 0 ? 0 : Double(filled) / Double(step)
        return Capsule()
            .fill(QCPalette.neutral)
            .frame(height: 6)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    Capsule()
                        .fill(QCPalette.pink)
                        .frame(width: geo.size.width * CGFloat(fraction))
                }
            }
            .clipShape(Capsule())
    }

    private func countLine(_ template: String, _ count: Int) -> String {
        let text = template.replacingOccurrences(of: "{count}", with: "\(count)")
        return count == 1 ? text.replacingOccurrences(of: "days", with: "day") : text
    }

    private func mark(index: Int, name: String, chosen: Bool) -> some View {
        let step = steps[index]
        let earned = days >= step
        let upcoming = !earned && steps.firstIndex { days < $0 } == index
        let ink = earned || upcoming ? QCPalette.ink : QCPalette.faint
        return Button {
            picked = index
        } label: {
            VStack(spacing: 6) {
                Text("\(step)")
                    .font(.system(size: step >= 100 ? 11 : 13, weight: .bold))
                    .foregroundStyle(ink)
                    .frame(width: 44, height: 44)
                    .background(earned ? QCPalette.pink : (upcoming ? Color.white : QCPalette.neutral), in: Circle())
                    .overlay(Circle().stroke(chosen ? QCPalette.ink : (upcoming ? QCPalette.pink : Color.clear), lineWidth: chosen ? 1.5 : 1))
                Text(name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
