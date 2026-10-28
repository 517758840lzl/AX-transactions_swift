import SwiftUI

struct SpendDonut: View {
    var parts: [CategoryPart]
    var total: Double
    var mark: String
    var caption: String
    var active: String?
    var onPick: (String) -> Void

    var body: some View {
        ZStack {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius: CGFloat = 50
                if total <= 0 || parts.isEmpty {
                    var ring = Path()
                    ring.addArc(center: center, radius: radius, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
                    context.stroke(ring, with: .color(Palette.line), lineWidth: 14)
                    return
                }
                let gap = parts.count > 1 ? 3 / radius : 0
                var start = -Double.pi / 2
                for part in parts {
                    let full = (part.amount / total) * Double.pi * 2
                    let sweep = parts.count > 1 ? max(full - Double(gap), 0.02) : full
                    var path = Path()
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .radians(start),
                        endAngle: .radians(start + sweep),
                        clockwise: false
                    )
                    let width: CGFloat = active == part.name ? 22 : 16
                    context.stroke(path, with: .color(Palette.slice(part.colorIndex)), style: StrokeStyle(lineWidth: width, lineCap: .butt))
                    start += full
                }
            }
            VStack(spacing: 1) {
                Text(caption)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.muted)
                Text(LedgerMoney.text(total, mark: mark))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .monospacedDigit()
            }
            .allowsHitTesting(false)
        }
        .frame(width: 130, height: 130)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0).onEnded { value in
                pick(at: value.location)
            }
        )
    }

    private func pick(at point: CGPoint) {
        guard total > 0 else { return }
        let center = CGPoint(x: 65, y: 65)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = hypot(dx, dy)
        guard distance > 34, distance < 74 else { return }
        var angle = atan2(dy, dx) + .pi / 2
        if angle < 0 { angle += .pi * 2 }
        var cursor = 0.0
        for part in parts {
            let sweep = (part.amount / total) * .pi * 2
            if angle >= cursor, angle < cursor + sweep {
                onPick(part.name)
                return
            }
            cursor += sweep
        }
    }
}
