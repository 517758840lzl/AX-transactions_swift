//
//  QCScrollPace.swift
//  transaction
//
//  Created by Lzl on 2026/10/4.
//

import SwiftUI
import UIKit

extension View {
    // A sombra tem de vir depois de achatar. Na árvore original, cada filho volta a ser desfocado a cada frame de scroll, e nota-se
    // do not move this above compositingGroup. scroll will drop frame, we test it already
    func plateShadow(opacity: Double = 0.05, radius: CGFloat = 14, y: CGFloat = 10) -> some View {
        compositingGroup()
            .shadow(color: QCPalette.ink.opacity(opacity), radius: radius, y: y)
    }

    // Start the drag immediately. place keeps the offset for when the page comes back.
    func immediateScroll(place: String? = nil) -> some View {
        background(QCScrollTouch(place: place))
    }

}

// Offset kept while a page is covered, restored when it comes back.
enum QCScrollPlace {
    static var y: [String: CGFloat] = [:]
}

private struct QCScrollTouch: UIViewRepresentable {
    var place: String?

    func makeUIView(context: Context) -> QCProbe {
        let view = QCProbe()
        view.place = place
        return view
    }

    func updateUIView(_ view: QCProbe, context: Context) {
        view.place = place
        view.tune()
    }

    final class QCProbe: UIView {
        var place: String?
        private weak var hookedScroll: UIScrollView?
        private var watch: NSKeyValueObservation?
        private var puttingBack = false

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            backgroundColor = .clear
        }

        required init?(coder: NSCoder) { nil }

        deinit {
            watch?.invalidate()
        }

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

        func tune() {
            var current: UIView? = self
            while let next = current {
                if let scroll = next as? UIScrollView {
                    scroll.delaysContentTouches = false
                    scroll.canCancelContentTouches = true
                    scroll.keyboardDismissMode = .onDrag
                    scroll.clipsToBounds = true
                    scroll.panGestureRecognizer.delaysTouchesBegan = false
                    guard hookedScroll !== scroll else {
                        putBack(scroll)
                        return
                    }
                    watch?.invalidate()
                    hookedScroll?.panGestureRecognizer.removeTarget(self, action: #selector(pageDrag))
                    scroll.panGestureRecognizer.addTarget(self, action: #selector(pageDrag))
                    hookedScroll = scroll
                    watch = scroll.observe(\.contentOffset, options: [.new]) { [weak self] scroll, _ in
                        self?.note(scroll)
                    }
                    putBack(scroll)
                    return
                }
                current = next.superview
            }
        }

        private func note(_ scroll: UIScrollView) {
            guard !puttingBack, let place else { return }
            let top = -scroll.adjustedContentInset.top
            let y = scroll.contentOffset.y
            if scroll.isTracking || scroll.isDragging || scroll.isDecelerating {
                QCScrollPlace.y[place] = y
                return
            }
            guard let kept = QCScrollPlace.y[place], kept > top + 12, y <= top + 1 else {
                QCScrollPlace.y[place] = y
                return
            }
            putBack(scroll)
        }

        private func putBack(_ scroll: UIScrollView) {
            guard !puttingBack, let place, let kept = QCScrollPlace.y[place] else { return }
            let top = -scroll.adjustedContentInset.top
            let limit = scroll.contentSize.height - scroll.bounds.height + scroll.adjustedContentInset.bottom
            guard kept > top + 12, limit > top + 12, scroll.contentOffset.y <= top + 1 else { return }
            let target = min(kept, limit)
            guard target > top + 12 else { return }
            puttingBack = true
            scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: target), animated: false)
            puttingBack = false
        }

        @objc private func pageDrag(_ gesture: UIPanGestureRecognizer) {
            if gesture.state == .began {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}
