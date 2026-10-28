//
//  OpeningCover.swift
//  transaction
//
//  Created by Lzl on 2026/10/28.
//

import Lottie
import SwiftUI

/// Opening sequence. Drop a `BrandMark` image into the asset catalog to fill the mark.
struct OpeningCover: View {
    var line: String
    var onComplete: () -> Void
    @State private var started = Date()
    @State private var finished = false

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(started)
            let master = min(max(elapsed / 2.2, 0), 1)
            let reveal = unit(master, from: 0, to: 0.45)
            let fade = unit(master, from: 0.1, to: 0.4)
            let scaleT = unit(master, from: 0.15, to: 0.55)
            let text = unit(master, from: 0.45, to: 0.85)

            ZStack {
                LinearGradient(
                    colors: [Color.white, Palette.wash],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                VStack(spacing: 0) {
                    BrandSlot(size: 112, reveal: reveal, fade: fade, scaleT: scaleT)
                    Text(BundleTitle.current)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(Palette.ink)
                        .padding(.top, 28)
                        .opacity(text)
                    Text(line)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Palette.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 36)
                        .padding(.top, 8)
                        .opacity(text)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Palette.down))
                        .padding(.top, 48)
                        .opacity(text)
                }
            }
            .ignoresSafeArea()
        }
        .task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard !finished else { return }
            finished = true
            onComplete()
        }
    }

    private func unit(_ value: Double, from start: Double, to end: Double) -> Double {
        if value <= start { return 0 }
        if value >= end { return 1 }
        let t = (value - start) / (end - start)
        return t * t * (3 - 2 * t)
    }
}

struct BrandSlot: View {
    var size: CGFloat
    var reveal: Double
    var fade: Double
    var scaleT: Double

    var body: some View {
        let popped = 0.82 + 0.18 * easeOutBack(scaleT)
        let shown = min(max(fade, 0), 1) * min(max(reveal, 0), 1)
        ZStack {
            LottieView(animation: .named("OpeningMark"))
                .playing(loopMode: .loop)
                .frame(width: size, height: size)
                .allowsHitTesting(false)
            mark
                .frame(width: size * 0.88, height: size * 0.88)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
                .scaleEffect(popped)
                .opacity(shown)
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var mark: some View {
        if let image = UIImage(named: "BrandMark") {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                        .stroke(Palette.line, lineWidth: 1)
                )
        }
    }

    private func easeOutBack(_ t: Double) -> Double {
        let c = 1.70158
        let x = t - 1
        return 1 + (c + 1) * x * x * x + c * x * x
    }
}
