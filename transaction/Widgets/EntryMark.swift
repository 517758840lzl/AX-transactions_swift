//
//  EntryMark.swift
//  transaction
//
//  Created by Lzl on 2026/10/29.
//

import SwiftUI

/// The little book on the add button. The line draws, then rests, then draws again.
struct EntryMark: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            EntryMarkFrame(date: context.date)
        }
    }
}

private struct EntryMarkFrame: View {
    var date: Date

    var body: some View {
        let cycle = 2.6
        let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle) / cycle
        let shown: CGFloat
        let fade: Double
        if phase < 0.45 {
            shown = phase / 0.45
            fade = 1
        } else if phase < 0.78 {
            shown = 1
            fade = 1
        } else {
            shown = 1
            fade = 1 - (phase - 0.78) / 0.22
        }
        let unit = CGFloat(34) / 32
        return ZStack {
            EntryBook()
            EntryCurve()
                .trim(from: 0, to: shown)
                .stroke(Palette.down, style: StrokeStyle(lineWidth: 1.7 * unit, lineCap: .round))
                .opacity(fade)
            Circle()
                .fill(Palette.down)
                .frame(width: 2.9 * unit, height: 2.9 * unit)
                .scaleEffect(shown > 0.72 ? 1 : 0.3)
                .opacity(shown > 0.72 ? fade : 0)
                .position(x: 23.15 * unit, y: 11.35 * unit)
        }
        .frame(width: 34, height: 34)
    }
}

private struct EntryBook: View {
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
        }
    }
}

/// Drag freely, then snap to the nearer side. A short tap still opens a new entry.
struct EntryButton: View {
    var title: String
    var onTap: () -> Void
    @State private var center = CGPoint.zero
    @State private var ready = false
    @State private var dragOrigin: CGPoint?
    @State private var holding = false

    var body: some View {
        GeometryReader { geo in
            let side: CGFloat = 56
            let edge: CGFloat = 24
            let top: CGFloat = max(geo.safeAreaInsets.top, 8) + side / 2
            let bottom = geo.size.height - 78 - side / 2
            let left = geo.safeAreaInsets.leading + edge + side / 2
            let right = geo.size.width - geo.safeAreaInsets.trailing - edge - side / 2

            EntryMark()
                .frame(width: side, height: side)
                .background(Palette.pink, in: Circle())
                .scaleEffect(holding ? 1.06 : 1)
                .position(ready ? center : CGPoint(x: right, y: bottom))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !ready {
                                center = CGPoint(x: right, y: bottom)
                                ready = true
                            }
                            if dragOrigin == nil {
                                dragOrigin = center
                                holding = true
                            }
                            let origin = dragOrigin ?? center
                            center = clamp(
                                CGPoint(
                                    x: origin.x + value.translation.width,
                                    y: origin.y + value.translation.height
                                ),
                                left: left,
                                right: right,
                                top: top,
                                bottom: bottom
                            )
                        }
                        .onEnded { value in
                            dragOrigin = nil
                            holding = false
                            let moved = hypot(value.translation.width, value.translation.height)
                            if moved < 8 {
                                onTap()
                                return
                            }
                            let docked = CGPoint(
                                x: center.x < geo.size.width / 2 ? left : right,
                                y: clamp(center, left: left, right: right, top: top, bottom: bottom).y
                            )
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                                center = docked
                            }
                            UserDefaults.standard.set(docked.x < geo.size.width / 2 ? "left" : "right", forKey: Self.sideKey)
                            UserDefaults.standard.set(Double(docked.y / max(geo.size.height, 1)), forKey: Self.heightKey)
                        }
                )
                .accessibilityLabel(title)
                .accessibilityAddTraits(.isButton)
                .onAppear {
                    place(in: geo.size, left: left, right: right, top: top, bottom: bottom)
                }
                .onChange(of: geo.size) { size in
                    place(in: size, left: left, right: right, top: top, bottom: bottom)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func place(in size: CGSize, left: CGFloat, right: CGFloat, top: CGFloat, bottom: CGFloat) {
        guard size.width > 1, size.height > 1 else { return }
        let side = UserDefaults.standard.string(forKey: Self.sideKey)
        let savedY = UserDefaults.standard.object(forKey: Self.heightKey) as? Double
        let x = side == "left" ? left : right
        let y = savedY.map { CGFloat($0) * size.height } ?? bottom
        center = clamp(CGPoint(x: x, y: y), left: left, right: right, top: top, bottom: bottom)
        ready = true
    }

    private func clamp(_ point: CGPoint, left: CGFloat, right: CGFloat, top: CGFloat, bottom: CGFloat) -> CGPoint {
        CGPoint(
            x: min(max(point.x, left), right),
            y: min(max(point.y, top), bottom)
        )
    }

    private static let sideKey = "entryDockSide"
    private static let heightKey = "entryDockHeight"
}

private struct EntryCurve: Shape {
    func path(in rect: CGRect) -> Path {
        let unit = rect.width / 32
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * unit, y: y * unit)
        }
        var path = Path()
        path.move(to: point(18.6, 18.8))
        path.addCurve(to: point(23.15, 12.35), control1: point(20.4, 18.2), control2: point(21.8, 15))
        return path
    }
}
