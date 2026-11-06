//
//  EntryMark.swift
//  transaction
//
//  Created by Lzl on 2026/10/29.
//

import SwiftUI

/// A pencil inside the floating button. The tip points down-left and tips back and forth.
struct WritingPen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                PencilGlyph()
                    .rotationEffect(.degrees(138))
                    .scaleEffect(1.12)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                    let wave = sin(context.date.timeIntervalSinceReferenceDate * .pi * 2 / 1.4)
                    PencilGlyph()
                        .rotationEffect(.degrees(138 + wave * 7))
                        .scaleEffect(1.12)
                }
            }
        }
        .frame(width: 40, height: 40)
        .accessibilityHidden(true)
    }
}

private struct PencilGlyph: View {
    var body: some View {
        Canvas { context, size in
            let ox = (size.width - 36) / 2
            let oy = (size.height - 14) / 2
            func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
                Path(roundedRect: CGRect(x: ox + x, y: oy + y, width: w, height: h), cornerRadius: r)
            }
            func fill(_ path: Path, _ color: Color) {
                context.fill(path, with: .color(color))
            }

            var wood = Path()
            wood.move(to: CGPoint(x: ox + 22.4, y: oy + 2.2))
            wood.addLine(to: CGPoint(x: ox + 22.4, y: oy + 11.8))
            wood.addLine(to: CGPoint(x: ox + 33.0, y: oy + 7))
            wood.closeSubpath()
            fill(wood, Color(red: 0.95, green: 0.84, blue: 0.66))

            fill(box(0.4, 2.6, 6.2, 8.8, 2.8), Color(red: 0.86, green: 0.33, blue: 0.48))
            fill(box(5.6, 2.0, 4.0, 10.0, 0.6), Color(red: 0.95, green: 0.93, blue: 0.90))
            fill(box(7.1, 2.0, 0.9, 10.0, 0), Color(red: 0.70, green: 0.67, blue: 0.64))
            fill(box(9.0, 2.2, 16.0, 9.6, 0.4), Color(red: 0.98, green: 0.78, blue: 0.20))

            var shine = Path()
            shine.move(to: CGPoint(x: ox + 11, y: oy + 4.2))
            shine.addLine(to: CGPoint(x: ox + 23.4, y: oy + 4.2))
            context.stroke(shine, with: .color(.white.opacity(0.7)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))

            var lead = Path()
            lead.move(to: CGPoint(x: ox + 30.2, y: oy + 5.3))
            lead.addLine(to: CGPoint(x: ox + 30.2, y: oy + 8.7))
            lead.addLine(to: CGPoint(x: ox + 34.8, y: oy + 7))
            lead.closeSubpath()
            fill(lead, Palette.ink)
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
