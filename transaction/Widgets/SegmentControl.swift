import SwiftUI

/// `.ledger-segment`. Wash track on a light page, translucent track on the dark hero.
struct SegmentControl: View {
    var labels: [String]
    var index: Int
    var onDark = false
    var onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(labels.indices, id: \.self) { item in
                Button {
                    onChange(item)
                } label: {
                    Text(labels[item])
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(labelColor(selected: item == index))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(item == index ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .compositingGroup()
                        .shadow(color: item == index && !onDark ? Palette.ink.opacity(0.06) : .clear, radius: 6, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(onDark ? Color.white.opacity(0.1) : Palette.wash, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func labelColor(selected: Bool) -> Color {
        if selected { return Palette.ink }
        return onDark ? Color.white.opacity(0.62) : Palette.muted
    }
}
