//
//  EdgeBack.swift
//  transaction
//
//  Created by Lzl on 2026/10/29.
//

import SwiftUI

/// Left-edge drag that pops the current page. Taps still reach the back button.
struct EdgeBack: UIViewRepresentable {
    var onChange: (CGFloat) -> Void
    var onEnd: (_ translation: CGFloat, _ velocity: CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onChange: onChange, onEnd: onEnd)
    }

    func makeUIView(context: Context) -> Probe {
        let view = Probe()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ view: Probe, context: Context) {
        context.coordinator.onChange = onChange
        context.coordinator.onEnd = onEnd
        view.coordinator = context.coordinator
        context.coordinator.attach(from: view)
    }

    final class Probe: UIView {
        weak var coordinator: Coordinator?

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            backgroundColor = .clear
        }

        required init?(coder: NSCoder) { nil }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            coordinator?.attach(from: self)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onChange: (CGFloat) -> Void
        var onEnd: (CGFloat, CGFloat) -> Void
        private weak var host: UIView?
        private var pan: UIPanGestureRecognizer?

        init(onChange: @escaping (CGFloat) -> Void, onEnd: @escaping (CGFloat, CGFloat) -> Void) {
            self.onChange = onChange
            self.onEnd = onEnd
        }

        func attach(from view: UIView) {
            var current: UIView? = view.superview
            var scroll: UIScrollView?
            var wide: UIView?
            while let next = current {
                if let found = next as? UIScrollView { scroll = found }
                if next.bounds.width > 200 { wide = next }
                current = next.superview
            }
            guard let target = scroll ?? wide, target !== host else { return }
            if let pan, let host { host.removeGestureRecognizer(pan) }
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(drag(_:)))
            gesture.delegate = self
            gesture.cancelsTouchesInView = false
            gesture.delaysTouchesBegan = false
            gesture.delaysTouchesEnded = false
            target.addGestureRecognizer(gesture)
            host = target
            pan = gesture
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
            let point = pan.location(in: view)
            let speed = pan.velocity(in: view)
            return point.x <= 32 && speed.x > 0 && abs(speed.x) > abs(speed.y)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool {
            guard let host, let pan, gestureRecognizer === pan, other === (host as? UIScrollView)?.panGestureRecognizer else { return false }
            return pan.location(in: host).x <= 32
        }

        @objc private func drag(_ pan: UIPanGestureRecognizer) {
            let space = pan.view?.window ?? pan.view
            let moved = max(0, pan.translation(in: space).x)
            let speed = pan.velocity(in: space).x
            switch pan.state {
            case .changed:
                onChange(moved)
            case .ended, .cancelled, .failed:
                onEnd(pan.state == .ended ? moved : 0, pan.state == .ended ? speed : 0)
            default:
                break
            }
        }
    }
}
