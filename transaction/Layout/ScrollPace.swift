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
}

private struct ScrollTouch: UIViewRepresentable {
    func makeUIView(context: Context) -> Probe { Probe() }
    func updateUIView(_ view: Probe, context: Context) {}

    final class Probe: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            backgroundColor = .clear
        }

        required init?(coder: NSCoder) { nil }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            var current: UIView? = self
            while let next = current {
                if let scroll = next as? UIScrollView {
                    scroll.delaysContentTouches = false
                    scroll.canCancelContentTouches = true
                    scroll.panGestureRecognizer.delaysTouchesBegan = false
                    return
                }
                current = next.superview
            }
        }
    }
}
