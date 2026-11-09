//
//  QCDashboardEmptyBanners.swift
//  transaction
//

//  Created by Lzl on 2026/11/1.
//

import SwiftUI

struct QCDashboardEmptyBanners: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    var copy: QCLedgerCopy
    private let artWeight: CGFloat = 7

    var body: some View {
        VStack(spacing: 12) {
            banner(title: copy.bannerEntryTitle, note: copy.bannerEntryNote, wash: true) {
                screen.openNewRecord(store: store)
            } art: {
                risingBars
            }
            banner(title: copy.bannerBudgetTitle, note: copy.bannerBudgetNote, wash: false) {
                screen.open(.budget)
            } art: {
                budgetRing
            }
        }
    }

    private func banner<Art: View>(
        title: String,
        note: String,
        wash: Bool,
        action: @escaping () -> Void,
        @ViewBuilder art: () -> Art
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .tracking(-0.32)
                        .foregroundStyle(QCPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(note)
                        .font(.system(size: 13))
                        .foregroundStyle(QCPalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                art()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardFill(wash))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(wash ? Color.clear : QCPalette.line.opacity(0.95), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func cardFill(_ wash: Bool) -> some View {
        if wash {
            LinearGradient(
                colors: [QCPalette.wash, Color(red: 1, green: 227 / 255, blue: 236 / 255)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.white
        }
    }

    private var risingBars: some View {
        HStack(alignment: .bottom, spacing: 5) {
            bar(14, opacity: 0.45)
            bar(24, opacity: 0.72)
            bar(36, opacity: 1)
        }
        .frame(height: 36, alignment: .bottom)
    }

    private func bar(_ height: CGFloat, opacity: Double) -> some View {
        Capsule()
            .fill(QCPalette.down.opacity(opacity))
            .frame(width: artWeight, height: height)
    }

    private var budgetRing: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.72)
                .stroke(QCPalette.pink, style: StrokeStyle(lineWidth: artWeight, lineCap: .butt))
            Circle()
                .trim(from: 0.72, to: 1)
                .stroke(QCPalette.wash, style: StrokeStyle(lineWidth: artWeight, lineCap: .butt))
        }
        .rotationEffect(.degrees(-90))
        .frame(width: 29, height: 29)
    }
}
