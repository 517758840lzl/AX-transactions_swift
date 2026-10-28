//
//  WorthTrendPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/28.
//

import SwiftUI

struct WorthSummary: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    var opens: Bool

    var body: some View {
        let copy = store.copy
        let days = BookMath.worthDays(screen.worthSpan, entries: store.book.entries)
        let snapshot = BookMath.windowSnapshot(
            accounts: store.book.accounts,
            entries: store.book.entries,
            holdings: store.book.holdings,
            days: days
        )
        let tone = snapshot.delta == 0 ? Palette.muted : Palette.down
        return VStack(spacing: 0) {
            summaryBody(copy, snapshot: snapshot, tone: tone)
            Rectangle().fill(Palette.line).frame(height: 1).padding(.horizontal, 16)
            HStack(spacing: 0) {
                ForEach(WorthSpan.allCases) { span in
                    let selected = screen.worthSpan == span
                    Button {
                        screen.worthSpan = span
                    } label: {
                        Text(copy.worthSpanTitle(span))
                            .font(.system(size: 13, weight: selected ? .bold : .semibold))
                            .foregroundStyle(selected ? Palette.ink : Palette.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(alignment: .bottom) {
                                if selected {
                                    Capsule().fill(Palette.pink).frame(height: 3).padding(.horizontal, 10)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Palette.line, lineWidth: 1))
        .plateShadow(opacity: 0.05, radius: 14, y: 10)
    }

    @ViewBuilder
    private func summaryBody(_ copy: LedgerCopy, snapshot: WindowSnapshot, tone: Color) -> some View {
        let block = summaryStack(copy, snapshot: snapshot, tone: tone)
        if opens {
            Button { screen.open(.worthTrend) } label: { block }
                .buttonStyle(.plain)
        } else {
            block
        }
    }

    private func summaryStack(_ copy: LedgerCopy, snapshot: WindowSnapshot, tone: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(copy.netAssets)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.muted)
                Spacer(minLength: 8)
                HStack(spacing: 4) {
                    Image(systemName: snapshot.delta < 0 ? "arrow.down.right" : "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                    Text(copy.worthPast(screen.worthSpan))
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(tone)
            }
            MoneyText(value: snapshot.netWorth, mark: store.book.mark, size: 32)
                .padding(.top, 8)
            HStack(alignment: .top, spacing: 12) {
                Text(copy.worthGrowth)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.muted)
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    MoneyText(value: snapshot.delta, mark: store.book.mark, size: 16, signed: true, color: tone)
                    Text(BookMath.formatPercent(delta: snapshot.delta, base: snapshot.prior))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(tone)
                }
            }
            .padding(.top, 14)
        }
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 14, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

struct WorthTrendPage: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen

    var body: some View {
        let copy = store.copy
        let days = BookMath.worthDays(screen.worthSpan, entries: store.book.entries)
        let snapshot = BookMath.windowSnapshot(
            accounts: store.book.accounts,
            entries: store.book.entries,
            holdings: store.book.holdings,
            days: days
        )
        FormPage(title: copy.netAssets, back: copy.back) {
            WorthSummary(store: store, screen: screen, opens: false)
            TrendChart(
                amounts: snapshot.amounts,
                fitDataRange: true,
                line: Palette.down,
                plotHeight: 200
            )
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Palette.line, lineWidth: 1))
            .plateShadow(opacity: 0.05, radius: 14, y: 10)
        }
    }
}
