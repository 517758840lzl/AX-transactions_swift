import SwiftUI

/// Language stays one row. Currency uses five equal columns, matching `.ledger-choice-row--wrap`.
struct ChoiceRow: View {
    var labels: [String]
    var index: Int
    var columns: Int?
    var onChange: (Int) -> Void

    var body: some View {
        if let columns {
            VStack(spacing: 8) {
                ForEach(rowStarts(columns), id: \.self) { start in
                    HStack(spacing: 8) {
                        ForEach(start..<min(start + columns, labels.count), id: \.self) { item in
                            chip(item, compact: true)
                        }
                        if labels.count - start < columns {
                            ForEach(0..<(columns - (labels.count - start)), id: \.self) { _ in
                                Color.clear.frame(maxWidth: .infinity).frame(height: 44)
                            }
                        }
                    }
                }
            }
        } else {
            HStack(spacing: 8) {
                ForEach(labels.indices, id: \.self) { item in
                    chip(item, compact: false)
                }
            }
        }
    }

    private func rowStarts(_ columns: Int) -> [Int] {
        Array(stride(from: 0, to: labels.count, by: columns))
    }

    private func chip(_ item: Int, compact: Bool) -> some View {
        let selected = item == index
        return Button {
            onChange(item)
        } label: {
            Text(labels[item])
                .font(.system(size: compact ? 12 : 13, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .padding(.horizontal, compact ? 4 : 10)
                .foregroundStyle(selected ? Palette.ink : Palette.muted)
                .background(selected ? Palette.pink : Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(selected ? Palette.pink : Palette.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
