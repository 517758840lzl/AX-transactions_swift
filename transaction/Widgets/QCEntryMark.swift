//
//  QCEntryMark.swift
//  transaction
//
//  Created by Lzl on 2026/10/29.
//

import SwiftUI

/// A pencil picture inside the floating button. The tip points down-left and tips back and forth.
struct QCWritingPen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                pencil
                    .rotationEffect(.degrees(138))
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                    let wave = sin(context.date.timeIntervalSinceReferenceDate * .pi * 2 / 1.4)
                    pencil
                        .rotationEffect(.degrees(138 + wave * 7))
                }
            }
        }
        .frame(width: 40, height: 40)
        .accessibilityHidden(true)
    }

    private var pencil: some View {
        Image("EntryPencil")
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
    }
}

/// Drag freely, then snap to the nearer side. A short tap still opens a new entry.
struct QCEntryButton: View {
    var title: String
    var onTap: () -> Void
    @State private var center = CGPoint.zero
    @State private var ready = false
    @State private var dragOrigin: CGPoint?
    @State private var holding = false

    var body: some View {
        GeometryReader { geo in
            let side: CGFloat = 56
            let edge: CGFloat = 6
            let top: CGFloat = max(geo.safeAreaInsets.top, 8) + side / 2
            let bottom = geo.size.height - 78 - side / 2
            let left = geo.safeAreaInsets.leading + edge + side / 2
            let right = geo.size.width - geo.safeAreaInsets.trailing - edge - side / 2

            QCWritingPen()
                .frame(width: side, height: side)
                .background(QCPalette.pink, in: Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: QCPalette.ink.opacity(0.18), radius: 10, y: 6)
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
