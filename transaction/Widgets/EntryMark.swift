//
//  EntryMark.swift
//  transaction
//
//  Created by Lzl on 2026/10/29.
//

import SwiftUI
import UIKit

/// A pen that draws one short stroke, rests, then draws it again.
struct WritingPen: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            WritingPenFrame(date: context.date)
        }
        .frame(width: 34, height: 34)
        .accessibilityHidden(true)
    }
}

private struct WritingPenFrame: View {
    var date: Date

    var body: some View {
        let draw = Self.draw(at: date)
        ZStack {
            WritingStroke()
                .trim(from: 0, to: draw.shown)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .opacity(draw.fade)
            PenBody()
                .position(WritingStroke.point(draw.shown))
                .opacity(draw.fade)
        }
        .frame(width: 34, height: 34)
    }

    private static func draw(at date: Date) -> (shown: CGFloat, fade: Double) {
        let cycle = 2.6
        let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle) / cycle
        if UIAccessibility.isReduceMotionEnabled { return (1, 1) }
        if phase < 0.45 { return (CGFloat(phase / 0.45), 1) }
        if phase < 0.78 { return (1, 1) }
        return (1, 1 - (phase - 0.78) / 0.22)
    }
}

private struct WritingStroke: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: Self.point(0))
        path.addQuadCurve(to: Self.point(1), control: Self.control)
        return path
    }

    static let start = CGPoint(x: 8, y: 24)
    static let control = CGPoint(x: 14, y: 22)
    static let end = CGPoint(x: 24, y: 12)

    static func point(_ t: CGFloat) -> CGPoint {
        let u = 1 - t
        return CGPoint(
            x: u * u * start.x + 2 * u * t * control.x + t * t * end.x,
            y: u * u * start.y + 2 * u * t * control.y + t * t * end.y
        )
    }
}

private struct PenBody: View {
    var body: some View {
        Canvas { context, size in
            let nib = CGPoint(x: size.width / 2, y: size.height / 2)
            var barrel = Path()
            barrel.addRoundedRect(
                in: CGRect(x: nib.x - 13, y: nib.y - 2.1, width: 11, height: 4.2),
                cornerSize: CGSize(width: 2, height: 2)
            )
            context.fill(barrel, with: .color(.white))
            var tip = Path()
            tip.move(to: nib)
            tip.addLine(to: CGPoint(x: nib.x - 3.4, y: nib.y - 2.3))
            tip.addLine(to: CGPoint(x: nib.x - 3.4, y: nib.y + 2.3))
            tip.closeSubpath()
            context.fill(tip, with: .color(.white))
        }
        .frame(width: 22, height: 22)
        .rotationEffect(.degrees(48))
        .shadow(color: Palette.ink.opacity(0.28), radius: 1.5, y: 1)
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
            let edge: CGFloat = 12
            let top: CGFloat = max(geo.safeAreaInsets.top, 8) + side / 2
            let bottom = geo.size.height - 78 - side / 2
            let left = geo.safeAreaInsets.leading + edge + side / 2
            let right = geo.size.width - geo.safeAreaInsets.trailing - edge - side / 2

            WritingPen()
                .frame(width: side, height: side)
                .background(Palette.pink, in: Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: Palette.ink.opacity(0.18), radius: 10, y: 6)
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
