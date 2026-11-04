//
//  DashboardView.swift
//  transaction
//
//  Created by Lzl on 2026/10/15.
//

import Combine
import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen

    var body: some View {
        let copy = store.copy
        let scoped = BookMath.byScope(store.book.entries, screen.dashScope).filter { !$0.id.hasPrefix("sample-") }
        let queue = BookMath.reviewQueue(scoped)

        PageScroll(bottom: 128) {
            HStack(spacing: 8) {
                Text(copy.monthTitle())
                    .font(.system(size: 26, weight: .bold))
                    .tracking(-0.4)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 8)
                Button {
                    screen.open(.filter(which: "dashboard"))
                } label: {
                    Text(screen.dashScope == .mine ? copy.scopeChipMine : copy.scopeChipFamily)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white, in: Capsule())
                        .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .fixedSize(horizontal: true, vertical: true)
            }
            DashboardStatsPanel(store: store, screen: screen, copy: copy, entries: scoped)
            DashboardClaimPanel(store: store, screen: screen, copy: copy)
            DashboardReviewPanel(store: store, screen: screen, copy: copy, queue: queue)
            DashboardRecurringPanel(store: store, screen: screen, copy: copy)
            if scoped.isEmpty {
                Button { screen.open(.entry(id: nil)) } label: {
                    HStack(spacing: 8) {
                        HStack(alignment: .bottom, spacing: 2.5) {
                            RoundedRectangle(cornerRadius: 1.5, style: .continuous).fill(Palette.down).frame(width: 5, height: 11)
                            RoundedRectangle(cornerRadius: 1.5, style: .continuous).fill(Palette.down).frame(width: 5, height: 17)
                            RoundedRectangle(cornerRadius: 1.5, style: .continuous).fill(Palette.down).frame(width: 5, height: 24)
                        }
                        .frame(width: 22, height: 24, alignment: .bottom)
                        Text(copy.statsQuiet)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Palette.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
