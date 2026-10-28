//
//  ScrollPace.swift
//  transaction
//
//  Created by Lzl on 2026/10/4.
//

import SwiftUI
import UIKit

extension View {
    /// Flatten the card into one layer, then blur that layer once.
    /// A shadow on the raw tree re-blurs every child on each scroll frame.
    func plateShadow(opacity: Double = 0.05, radius: CGFloat = 14, y: CGFloat = 10) -> some View {
        compositingGroup()
            .shadow(color: Palette.ink.opacity(opacity), radius: radius, y: y)
    }

    /// Let a drag start immediately instead of waiting to see if it was a button tap.
    func immediateScroll() -> some View {
        background(ScrollTouch())
    }

    /// Decimal pads have no return key. A keyboard bar gives them a way to close.
    func keyboardBar(_ title: String) -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(title) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}

private struct ScrollTouch: UIViewRepresentable {
    func makeUIView(context: Context) -> Probe { Probe() }
    func updateUIView(_ view: Probe, context: Context) {}

    final class Probe: UIView {
        private weak var hookedScroll: UIScrollView?

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            backgroundColor = .clear
        }

        required init?(coder: NSCoder) { nil }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            tune()
        }

        override func didMoveToSuperview() {
            super.didMoveToSuperview()
            tune()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            tune()
        }

        private func tune() {
            var current: UIView? = self
            while let next = current {
                if let scroll = next as? UIScrollView {
                    scroll.delaysContentTouches = false
                    scroll.canCancelContentTouches = true
                    scroll.keyboardDismissMode = .onDrag
                    scroll.panGestureRecognizer.delaysTouchesBegan = false
                    guard hookedScroll !== scroll else { return }
                    hookedScroll?.panGestureRecognizer.removeTarget(self, action: #selector(pageDrag))
                    scroll.panGestureRecognizer.addTarget(self, action: #selector(pageDrag))
                    hookedScroll = scroll
                    return
                }
                current = next.superview
            }
        }

        @objc private func pageDrag(_ gesture: UIPanGestureRecognizer) {
            if gesture.state == .began {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}
